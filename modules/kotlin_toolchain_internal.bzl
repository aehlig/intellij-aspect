# Copyright 2026 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@rules_kotlin//kotlin/internal:defs.bzl", "TOOLCHAIN_TYPE")
load("//common:common.bzl", "intellij_common")
load(":provider.bzl", "intellij_provider")

def _aspect_impl(target, ctx):
    if not platform_common.ToolchainInfo in target:
        return [intellij_provider.KotlinToolchainInternal(present = False)]
    return [
        intellij_provider.create(
            ctx = ctx,
            value = intellij_common.struct(),
            provider = intellij_provider.KotlinToolchainInternal,
            internal_value = intellij_common.struct(
                toolchain_info = target[platform_common.ToolchainInfo],
            ),
        ),
    ]

intellij_kotlin_toolchain_internal = intellij_common.aspect(
    implementation = _aspect_impl,
    provides = [intellij_provider.KotlinToolchainInternal],
    toolchains_aspects = [TOOLCHAIN_TYPE],
)
