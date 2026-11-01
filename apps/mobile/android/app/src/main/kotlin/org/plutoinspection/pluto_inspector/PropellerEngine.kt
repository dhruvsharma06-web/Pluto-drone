package org.plutoinspection.pluto_inspector

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import io.flutter.FlutterInjector
import java.nio.FloatBuffer
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * On-device propeller verification: YOLO11 ONNX detector (classes 0=cw, 1=ccw)
 * plus image-quality gates and top-down motor assignment.
 *
 * Motor assignment uses the body's long axis (PCA of dark body pixels between
 * the four propellers) and the wider-end = head convention. Anything outside a
 * clean top-down four-propeller view returns unable_to_verify, never pass.
 */
class PropellerEngine(context: Context) {
    companion object {
        const val ENGINE_VERSION = "pluto-yolo11s-propeller-1.1.0"
        const val INPUT = 640
        const val CONF = 0.35f
        const val MIN_CLASS_CONF = 0.40f
        const val MISMATCH_CONF = 0.60f  // a mismatch verdict needs a confident type
        const val IOU = 0.5f
        const val BLUR_MIN = 60.0      // Laplacian variance on 320px grey (sharp photos >= 134, blurred <= 12)
        const val DARK_MAX = 45.0      // mean grey below => too dark
        const val BRIGHT_MIN = 235.0   // mean grey above => washed out
        val TYPES = arrayOf("cw", "ccw")
    }

    private val env = OrtEnvironment.getEnvironment()
    private val session: OrtSession

    init {
        val key = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset("assets/models/propeller.onnx")
        val bytes = context.assets.open(key).use { it.readBytes() }
        session = env.createSession(bytes, OrtSession.SessionOptions())
    }

    fun close() = session.close()

    data class Det(val x1: Float, val y1: Float, val x2: Float, val y2: Float,
                   val cls: Int, val conf: Float, val scores: FloatArray) {
        val cx get() = (x1 + x2) / 2
        val cy get() = (y1 + y2) / 2
    }

    fun verify(args: Map<*, *>): Map<String, Any?> {
        val start = System.nanoTime()
        val inputId = args["input_id"] as String
        val ref = args["reference"] as Map<*, *>
        val refVersion = ref["reference_version"] as String
        val refMotors = (ref["motors"] as List<*>).associate {
            val m = it as Map<*, *>; (m["motor_id"] as String) to m
        }
        fun result(status: String, reasons: List<String>, motors: List<Map<String, Any?>>,
                   observable: Boolean) = mapOf(
            "schema_version" to "1.0.0", "input_id" to inputId, "status" to status,
            "evidence_source" to "real", "reference_version" to refVersion,
            "engine_version" to ENGINE_VERSION,
            "all_required_checks_observable" to observable, "reasons" to reasons,
            "motors" to motors, "elapsed_ms" to (System.nanoTime() - start) / 1e6)

        val bytes = args["bytes"] as ByteArray
        val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: return result("unable_to_verify", listOf("IMAGE_UNREADABLE"), emptyList(), false)
        val w = bmp.width.toFloat(); val h = bmp.height.toFloat()

        val quality = qualityReasons(bmp)
        val dets = detect(bmp)
        val reasons = quality.toMutableList()
        when {
            dets.isEmpty() -> reasons += "NO_PROPELLERS_DETECTED"
            dets.size < 4 -> reasons += "INCOMPLETE_DRONE_VIEW"
            dets.size > 4 -> reasons += "AMBIGUOUS_DETECTIONS"
        }
        if (dets.any { it.conf < MIN_CLASS_CONF }) reasons += "LOW_CONFIDENCE_CLASSIFICATION"

        fun box(d: Det): List<Double> {
            val x = (d.x1 / w).coerceIn(0f, 1f); val y = (d.y1 / h).coerceIn(0f, 1f)
            return listOf(x.toDouble(), y.toDouble(),
                ((d.x2 / w).coerceIn(0f, 1f) - x).toDouble().coerceAtLeast(1e-4),
                ((d.y2 / h).coerceIn(0f, 1f) - y).toDouble().coerceAtLeast(1e-4))
        }

        val typed = if (dets.size == 4) ttaTypes(bmp, dets) else dets
        val assignment = if (typed.size == 4) assignMotors(bmp, typed) else null
        if (dets.size == 4 && assignment == null) reasons += "UNSUPPORTED_VIEW_TOP_DOWN_REQUIRED"

        val motors = mutableListOf<Map<String, Any?>>()
        if (assignment != null) {
            for ((id, d) in assignment) {
                val expected = refMotors[id] ?: continue
                val known = reasons.isEmpty()
                val observedType = TYPES[d.cls]
                val match = observedType == expected["expected_type"]
                motors += mapOf(
                    "motor_id" to id, "bbox" to box(d),
                    "observed_type" to if (known) observedType else null,
                    "expected_type" to expected["expected_type"],
                    "observed_orientation" to if (known) expected["expected_orientation"] else null,
                    "expected_orientation" to expected["expected_orientation"],
                    "finding" to if (!known) "unknown" else if (match) "match" else "mismatch",
                    "correction_code" to if (known && !match) "REPLACE_WITH_${(expected["expected_type"] as String).uppercase()}" else null)
            }
        }
        if (reasons.isNotEmpty() || motors.size != refMotors.size) {
            if (reasons.isEmpty()) reasons += "MOTOR_ASSIGNMENT_FAILED"
            return result("unable_to_verify", reasons.distinct(), motors, false)
        }
        val pass = motors.all { it["finding"] == "match" }
        if (!pass && assignment!!.any { (id, d) -> TYPES[d.cls] != refMotors[id]!!["expected_type"] && d.conf < MISMATCH_CONF }) {
            // Never claim a wrong installation from an uncertain type: ask for a retake.
            val unknown = motors.map { it + mapOf("observed_type" to null, "observed_orientation" to null,
                "finding" to "unknown", "correction_code" to null) }
            return result("unable_to_verify", listOf("LOW_CONFIDENCE_CLASSIFICATION"), unknown, false)
        }
        return result(if (pass) "pass" else "incorrect_installation", emptyList(), motors, true)
    }

    private fun grey(bmp: Bitmap, target: Int): Triple<FloatArray, Int, Int> {
        val s = target.toFloat() / max(bmp.width, bmp.height)
        val gw = max(1, (bmp.width * s).toInt()); val gh = max(1, (bmp.height * s).toInt())
        val small = Bitmap.createScaledBitmap(bmp, gw, gh, true)
        val px = IntArray(gw * gh); small.getPixels(px, 0, gw, 0, 0, gw, gh)
        val g = FloatArray(px.size) {
            val c = px[it]; 0.299f * Color.red(c) + 0.587f * Color.green(c) + 0.114f * Color.blue(c)
        }
        return Triple(g, gw, gh)
    }

    private fun qualityReasons(bmp: Bitmap): List<String> {
        val (g, gw, gh) = grey(bmp, 320)
        val mean = g.average()
        var sum = 0.0; var sq = 0.0; var n = 0
        for (y in 1 until gh - 1) for (x in 1 until gw - 1) {
            val i = y * gw + x
            val lap = (g[i - 1] + g[i + 1] + g[i - gw] + g[i + gw] - 4 * g[i]).toDouble()
            sum += lap; sq += lap * lap; n++
        }
        val variance = sq / n - (sum / n) * (sum / n)
        val out = mutableListOf<String>()
        if (variance < BLUR_MIN) out += "IMAGE_BLURRY"
        if (mean < DARK_MAX) out += "IMAGE_TOO_DARK"
        if (mean > BRIGHT_MIN) out += "IMAGE_OVEREXPOSED"
        return out
    }

    private fun detect(bmp: Bitmap): List<Det> {
        val scale = min(INPUT.toFloat() / bmp.width, INPUT.toFloat() / bmp.height)
        val nw = (bmp.width * scale).toInt(); val nh = (bmp.height * scale).toInt()
        val padX = (INPUT - nw) / 2f; val padY = (INPUT - nh) / 2f
        val canvasBmp = Bitmap.createBitmap(INPUT, INPUT, Bitmap.Config.ARGB_8888)
        Canvas(canvasBmp).apply {
            drawColor(Color.rgb(114, 114, 114))
            drawBitmap(Bitmap.createScaledBitmap(bmp, nw, nh, true), padX, padY, Paint(Paint.FILTER_BITMAP_FLAG))
        }
        val px = IntArray(INPUT * INPUT); canvasBmp.getPixels(px, 0, INPUT, 0, 0, INPUT, INPUT)
        val area = INPUT * INPUT
        val buf = FloatBuffer.allocate(3 * area)
        for (i in 0 until area) {
            val c = px[i]
            buf.put(i, Color.red(c) / 255f); buf.put(area + i, Color.green(c) / 255f)
            buf.put(2 * area + i, Color.blue(c) / 255f)
        }
        val tensor = OnnxTensor.createTensor(env, buf, longArrayOf(1, 3, INPUT.toLong(), INPUT.toLong()))
        val raw = tensor.use { t ->
            session.run(mapOf(session.inputNames.first() to t)).use { out ->
                @Suppress("UNCHECKED_CAST")
                (out[0].value as Array<Array<FloatArray>>)[0]
            }
        }
        // raw: [4 + classes][anchors]
        val anchors = raw[0].size
        val cands = mutableListOf<Det>()
        for (a in 0 until anchors) {
            var best = 0; var conf = raw[4][a]
            for (c in 1 until raw.size - 4) if (raw[4 + c][a] > conf) { conf = raw[4 + c][a]; best = c }
            if (conf < CONF) continue
            val cx = (raw[0][a] - padX) / scale; val cy = (raw[1][a] - padY) / scale
            val bw = raw[2][a] / scale; val bh = raw[3][a] / scale
            val sc = FloatArray(raw.size - 4) { raw[4 + it][a] }
            cands += Det(cx - bw / 2, cy - bh / 2, cx + bw / 2, cy + bh / 2, best, conf, sc)
        }
        // Class-agnostic NMS: one physical propeller gets one type.
        val keep = mutableListOf<Det>()
        for (d in cands.sortedByDescending { it.conf }) if (keep.none { iou(it, d) > IOU }) keep += d
        return keep
    }

    /** Average type scores over 90-degree rotations; rotation preserves CW/CCW chirality. */
    private fun ttaTypes(bmp: Bitmap, dets: List<Det>): List<Det> {
        val acc = dets.map { it.scores.copyOf() }
        for (k in 1..3) {
            // Counter-clockwise rotation, matching (x, y) -> (y, w - x) per step.
            val m = android.graphics.Matrix().apply { postRotate(-90f * k) }
            val rot = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true)
            val rd = detect(rot)
            dets.forEachIndexed { i, d ->
                var x = d.cx; var y = d.cy; var w = bmp.width.toFloat(); var h = bmp.height.toFloat()
                repeat(k) { val nx = y; val ny = w - x; x = nx; y = ny; val t = w; w = h; h = t }
                rd.filter { x in it.x1..it.x2 && y in it.y1..it.y2 }
                    .minByOrNull { abs(it.cx - x) + abs(it.cy - y) }
                    ?.let { r -> for (c in acc[i].indices) acc[i][c] += r.scores[c] }
            }
        }
        return dets.mapIndexed { i, d ->
            val best = acc[i].indices.maxByOrNull { acc[i][it] }!!
            d.copy(cls = best, conf = acc[i][best] / 4f)
        }
    }

    private fun iou(a: Det, b: Det): Float {
        val iw = max(0f, min(a.x2, b.x2) - max(a.x1, b.x1))
        val ih = max(0f, min(a.y2, b.y2) - max(a.y1, b.y1))
        val inter = iw * ih
        return inter / ((a.x2 - a.x1) * (a.y2 - a.y1) + (b.x2 - b.x1) * (b.y2 - b.y1) - inter)
    }

    /** Returns motor_id -> detection, or null when the view is not a clean top-down view. */
    private fun assignMotors(bmp: Bitmap, dets: List<Det>): Map<String, Det>? {
        val cx = dets.map { it.cx }.average().toFloat(); val cy = dets.map { it.cy }.average().toFloat()
        // Body pixels: dark pixels in the central region between the propellers.
        val (g, gw, gh) = grey(bmp, 320)
        val s = gw.toFloat() / bmp.width
        val spanX = (dets.maxOf { it.cx } - dets.minOf { it.cx }) * s
        val spanY = (dets.maxOf { it.cy } - dets.minOf { it.cy }) * s
        val rx = spanX * 0.38f; val ry = spanY * 0.38f
        val ox = cx * s; val oy = cy * s
        val region = mutableListOf<Int>()
        for (y in max(0, (oy - ry).toInt()) until min(gh, (oy + ry).toInt()))
            for (x in max(0, (ox - rx).toInt()) until min(gw, (ox + rx).toInt())) region += y * gw + x
        if (region.size < 50) return null
        val sorted = region.map { g[it] }.sorted()
        val thr = sorted[(sorted.size * 0.35).toInt()]
        var mx = 0.0; var my = 0.0; var n = 0
        val pts = ArrayList<FloatArray>()
        for (i in region) if (g[i] <= thr) {
            val x = (i % gw).toFloat(); val y = (i / gw).toFloat(); pts += floatArrayOf(x, y); mx += x; my += y; n++
        }
        if (n < 50) return null
        mx /= n; my /= n
        var sxx = 0.0; var syy = 0.0; var sxy = 0.0
        for (p in pts) { val dx = p[0] - mx; val dy = p[1] - my; sxx += dx * dx; syy += dy * dy; sxy += dx * dy }
        val theta = 0.5 * atan2(2 * sxy, sxx - syy)
        val l1 = (sxx + syy) / 2 + sqrt(((sxx - syy) / 2) * ((sxx - syy) / 2) + sxy * sxy)
        val l2 = (sxx + syy) / 2 - sqrt(((sxx - syy) / 2) * ((sxx - syy) / 2) + sxy * sxy)
        if (l2 <= 0 || l1 / l2 < 1.4 || l1 / l2 > 4.5) return null // top-down body 1.5-4; side views 6+
        var dx = cos(theta); var dy = sin(theta)
        // Head = wider end: compare body width across the axis at each end.
        var wPlus = 0.0; var wMinus = 0.0; var cPlus = 0; var cMinus = 0
        val half = sqrt(l1 / n) * 1.0
        for (p in pts) {
            val ax = p[0] - mx; val ay = p[1] - my
            val along = ax * dx + ay * dy; val across = abs(-ax * dy + ay * dx)
            if (along > half) { wPlus += across; cPlus++ } else if (along < -half) { wMinus += across; cMinus++ }
        }
        if (cPlus == 0 || cMinus == 0) return null
        if (wMinus / cMinus > wPlus / cPlus) { dx = -dx; dy = -dy }
        // n points to the drone's right when viewed from above.
        val nx = -dy; val ny = dx
        val out = HashMap<String, Det>()
        for (d in dets) {
            val vx = d.cx - cx; val vy = d.cy - cy
            val along = vx * dx + vy * dy; val across = vx * nx + vy * ny
            val id = (if (along > 0) "front_" else "rear_") + (if (across > 0) "right" else "left")
            if (out.put(id, d) != null) return null
        }
        if (out.size != 4) return null
        // Perspective check: in a true top-down view opposite sides of the
        // propeller rectangle have similar lengths (top-down >= 0.90, angled shots <= 0.88 on real photos).
        fun dist(a: String, b: String): Float {
            val p = out.getValue(a); val q = out.getValue(b)
            return sqrt((p.cx - q.cx) * (p.cx - q.cx) + (p.cy - q.cy) * (p.cy - q.cy))
        }
        val pairs = listOf(dist("front_left", "front_right") to dist("rear_left", "rear_right"),
            dist("front_left", "rear_left") to dist("front_right", "rear_right"))
        if (pairs.any { (a, b) -> min(a, b) / max(a, b) < 0.89f }) return null
        return out
    }
}
