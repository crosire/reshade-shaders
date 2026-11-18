# THIRD-PARTY NOTICES

This document identifies third-party source code, scientific publications, algorithmic references, and technical inspirations relevant to USS-VisualEngine.

It distinguishes between source code incorporated into the project and external works consulted as references during development.

Acknowledging an algorithmic reference does not mean that the original source code, shader, or assets are included in USS-VisualEngine.

---

## 1. ACES RRT/ODT Fit

USS-VisualEngine includes an adapted implementation of the `rrt_odt_fit` function from the following source:

**Original source:**

https://github.com/selfshadow/ltc_code/blob/master/webgl/shaders/ltc/ltc_blit.fs

**Original repository:**

https://github.com/selfshadow/ltc_code

**Copyright (c) 2017, Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt.**

### Required Academic Reference

Real-Time Polygonal-Light Shading with Linearly Transformed Cosines.

Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt.

ACM Transactions on Graphics (Proceedings of ACM SIGGRAPH 2016), 35(4), 2016.

Project page:

https://eheitzresearch.wordpress.com/415-2/

### Original License Terms

Copyright (c) 2017, Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. If you use (or adapt) the source code in your own work, please include a reference to the paper:

   Real-Time Polygonal-Light Shading with Linearly Transformed Cosines.

   Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt.

   ACM Transactions on Graphics (Proceedings of ACM SIGGRAPH 2016) 35(4), 2016.

   Project page: https://eheitzresearch.wordpress.com/415-2/

2. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

3. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

## 2. Color Vision Simulation

The color vision simulation matrices used in USS-VisualEngine are based on the scientific model described in the following publication:

**Authors:**

Gustavo M. Machado, Manuel M. Oliveira, and Leandro A. F. Fernandes.

**Publication:**

"A Physiologically-based Model for Simulation of Color Vision Deficiency."

IEEE Transactions on Visualization and Computer Graphics, Volume 15, Issue 6, 2009, pages 1291–1298.

**DOI:**

https://doi.org/10.1109/TVCG.2009.113

This citation acknowledges the scientific model underlying the color vision simulation matrices.

The additional color assistance and remapping operations are implemented within USS-VisualEngine.

This notice does not claim that the paper's software source code is included in the project.

---

## 3. Algorithmic References and Inspirations

The following projects were consulted during the development of USS-VisualEngine and its earlier NeuralFusion implementations.

They are acknowledged as technical and algorithmic references. Their inclusion here does not mean that their original shader source code or assets are distributed as part of USS-VisualEngine.

### 3.1 Zenteon Local Contrast v0.2

**Author:** Daniel Oren-Ibarra (Zenteon)

**Original project:**

https://github.com/Zenteon/ZenteonFX/blob/main/Shaders/Zenteon_LocalContrast.fx

Zenteon Local Contrast was consulted as an algorithmic reference for multi-scale local-contrast processing and luminance analysis.

The local-contrast implementation in USS-VisualEngine uses a project-specific implementation, including its own luminance pyramid, scale blending, contrast calculations, and edge protection.

No original Zenteon source-code functions are intentionally incorporated into USS-VisualEngine.

The original Zenteon shader identifies its source as All Rights Reserved. This acknowledgment does not grant permission to copy or redistribute that original source code.

### 3.2 Blooming HDR

**Author:** Jose Negrete (BlueSkyDefender)

**Original project:**

https://github.com/BlueSkyDefender/AstrayFX/blob/master/Shaders/BloomingHDR.fx

**Original license information:**

The original shader identifies Blooming HDR material as licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0).

https://creativecommons.org/licenses/by-sa/4.0/

Blooming HDR was consulted as a technical reference for HDR highlight extraction, exposure handling, and bloom processing.

USS-VisualEngine implements its own bloom extraction, filtering, exposure adaptation, and compositing logic.

No original Blooming HDR shader file or texture asset is intentionally included in USS-VisualEngine.

This acknowledgment identifies conceptual and algorithmic inspiration; it does not claim that CC BY-SA-licensed source code is incorporated into the project.

### 3.3 Magic Bloom

**Author:** luluco250

**Original project:**

https://reshade.me/forum/shader-presentation/2995-magic-bloom

**Original license:**

MIT License.

**Copyright (c) 2017 luluco250.**

Magic Bloom was consulted as a technical reference for wide bloom filtering, multi-scale glow, and image-luminance-based adaptation.

USS-VisualEngine uses its own shared bloom pyramid, filtering functions, exposure logic, and compositing implementation.

No original Magic Bloom shader source code or texture assets are intentionally included in USS-VisualEngine.

This acknowledgment does not imply that the original shader is redistributed as part of the project.

### 3.4 Karis-Style Luminance-Weighted Downsampling

**Reference:** Brian Karis, Graphic Rants — Tone Mapping.

https://graphicrants.blogspot.com/2013/12/tone-mapping.html

USS-VisualEngine implements luminance-dependent sample weighting during bloom downsampling, using a Karis-style approach to reduce the influence of isolated extremely bright samples.

The implementation in USS-VisualEngine uses its own sampling structure and weighting integration.

This entry acknowledges the algorithmic reference and does not indicate that external shader source code is included.

### Reference Scope

The references in this section acknowledge the technical ideas and development context that informed some of the project's algorithms.

The current USS-VisualEngine implementation uses project-specific shader functions, sampling structures, coefficients, render passes, and integration.

No complete external shader implementation from the projects listed above has been identified as incorporated into the reviewed USS-VisualEngine source.

This statement describes the results of the available source review and is not a guarantee that no similarities exist with other published implementations.

---

## 4. Project Development Credits

**Project:** USS-VisualEngine

**Full name:** Universal Screen-Space Visual Engine

**Project Author and Maintainer:** Elshad03

**AI Development Assistant:** ChatGPT (OpenAI)

### Human Development Contributions — Elshad03

- Project concept, direction, and feature requirements.
- Direct shader and HLSL code contributions.
- Technical decisions and feature selection.
- Testing, calibration, and visual evaluation.
- Code review, integration, and development feedback.
- Project maintenance and release decisions.

### AI Development Contributions — ChatGPT (OpenAI)

- Writing and generating shader code (HLSL, ReShade).
- Designing shader architecture and implementing algorithms.
- Developing shader modules and processing pipelines.
- Preparing documentation and release materials.

ChatGPT assisted with the initial drafting and implementation of the shader code, while Elshad03 directly wrote, modified, tested, and integrated the code, and guided the technical development.

These credits acknowledge the respective development contributions. The AI acknowledgment does not designate ChatGPT as a legal co-author or copyright holder.

Copyright and project-maintainer attribution remain as specified in the repository's LICENSE file.

---

## 5. Project License

Except for third-party source material explicitly identified in this document, the original USS-VisualEngine project code and implementations are distributed under the MIT License included in the repository.

The MIT License applies to the project's original contributions as identified by the repository license.

It does not replace, override, or expand the license conditions applicable to third-party source code.

Algorithmic references and academic citations in this document do not, by themselves, constitute the inclusion of third-party source code in USS-VisualEngine.

---

## 6. Source Distribution Notice

When redistributing the USS-VisualEngine source file containing the adapted `rrt_odt_fit` implementation, include this `THIRD-PARTY-NOTICES.md` file in the same source distribution.

This preserves the required copyright notice, license conditions, disclaimer, and academic reference associated with the adapted implementation.

For complete license information, refer to both this document and the repository's `LICENSE` file.

---

**USS-VisualEngine**

Universal Screen-Space Visual Engine

Project Author and Maintainer: Elshad03

AI Development Assistant: ChatGPT (OpenAI)
