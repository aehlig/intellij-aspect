# Copyright 2026 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@protobuf//bazel/common:proto_common.bzl", "proto_common")
load("@protobuf//bazel/common:proto_info.bzl", "ProtoInfo")
load("//common:artifact_location.bzl", "artifact_location")
load("//common:common.bzl", "intellij_common")
load(":provider.bzl", "intellij_provider")

def _get_import_path(proto_file):
    if hasattr(proto_common, "get_import_path"):
        return proto_common.get_import_path(proto_file)

    # Fall-back code taken from
    # https://github.com/protocolbuffers/protobuf/blob/cbaf01ac1604e4bcb12552ca3b52fecd21f3e01b/bazel/common/proto_common.bzl#L58
    #
    # Protocol Buffers - Google's data interchange format
    # Copyright 2024 Google Inc.  All rights reserved.
    #
    # Use of this source code is governed by a BSD-style
    # license that can be found in the LICENSE file or at
    # https://developers.google.com/open-source/licenses/bsd
    #
    def _remove_repo(file):
        """Removes `../repo/` prefix from path, e.g. `../repo/package/path -> package/path`"""
        short_path = file.short_path
        workspace_root = file.owner.workspace_root
        if workspace_root:
            if workspace_root.startswith("external/"):
                workspace_root = "../" + workspace_root.removeprefix("external/")
            return short_path.removeprefix(workspace_root + "/")
        return short_path

    repo_path = _remove_repo(proto_file)
    index = repo_path.find("_virtual_imports/")
    if index >= 0:
        index = repo_path.find("/", index + len("_virtual_imports/"))
        repo_path = repo_path[index + 1:]
    return repo_path

def _source_mappings(target):
    mappings = []
    for source in target[ProtoInfo].direct_sources:
        proto = intellij_common.struct(
            import_path = _get_import_path(source),
            proto_file = artifact_location.from_file(source),
        )
        mappings.append(proto)
    return mappings

def _aspect_impl(target, ctx):
    if not ProtoInfo in target:
        return [intellij_provider.ProtobufInfo(present = False)]
    return [
        intellij_provider.create(
            ctx = ctx,
            provider = intellij_provider.ProtobufInfo,
            value = intellij_common.struct(
                source_mappings = _source_mappings(target),
            ),
        ),
    ]

intellij_protobuf_info_aspect = intellij_common.aspect(
    implementation = _aspect_impl,
    provides = [intellij_provider.ProtobufInfo],
)
