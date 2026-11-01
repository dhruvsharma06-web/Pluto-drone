# Architecture

Flutter Android shell -> inspection_ui (presentation) -> InspectionController contract -> inspection_runtime (camera/import/lifecycle/state) -> VerificationEngine contract -> portable vision/model adapter -> reference comparison -> versioned structured result.

Website is independent and consumes only approved project content/assets. No inference backend or persistence is currently required. Python may support data/training/evaluation; Android cannot be considered functional until an actual Android-compatible core/model executes there. C++/OpenCV with a native bridge is the starting candidate; app and ML owners must prove feasibility against installed tooling before committing to a model runtime. Future platform reuse is an architectural goal, not a tested-platform claim.

Core receives encoded upright unmirrored images (JPEG/PNG), input ID and verified reference. App normalizes acquisition; core's preprocessing must match training/evaluation. Result bounding boxes are normalized [x,y,width,height] in that analyzed image. App/UI must map to preview crop/letterbox/mirror. Motor IDs are reference identities, not screen corners. Frame backpressure and stale-result suppression belong to runtime.

Baseline is intentionally incomplete: no camera, inference/model, real dataset or verified motor map. It runs only a safe pending screen/controller. Independent development uses shared labelled fixtures; final integration combines branches in integration/final.
