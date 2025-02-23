(**************************************************************************)
(*                                                                        *)
(*    Copyright 2017-2019 OCamlPro                                        *)
(*                                                                        *)
(*  All rights reserved. This file is distributed under the terms of the  *)
(*  GNU Lesser General Public License version 2.1, with the special       *)
(*  exception on linking described in the file LICENSE.                   *)
(*                                                                        *)
(**************************************************************************)

(** Some command helpers, and auxiliary opam management functions used by the
    CLI *)

open OpamTypes
open OpamStateTypes

(** Gets the file changes done in the installation of the given packages in the
    given switch, and copies the corresponding files to the same relative paths
    below the given prefix ; files that are not current according to the
    recorded package changes print warnings and aren't copied. *)
val copy_files_to_destdir: 'a switch_state -> dirname -> package_set -> unit

(** Removes all files that may have been installed by {!copy_files_to_destdir};
    it's more aggressive than {!OpamDirTrack.revert} and doesn't check if the
    files are current. *)
val remove_files_from_destdir: 'a switch_state -> dirname -> package_set -> unit

(** If the URL points to a local, version-controlled directory, qualify it by
    suffixing `#current-branch` if no branch/tag/hash was specified. *)
val url_with_local_branch: url -> url

(** From an in-source opam file, return the corresponding package name if it can
    be found, and the corresponding source directory *)
val name_and_dir_of_opam_file: ?locked:string -> filename -> name option * dirname

(** From a directory, retrieve its opam files and returns packages name, opam
    file and subpath option *)
val opams_of_dir:
  ?locked:string -> ?recurse:bool -> ?subpath:subpath ->
  OpamFilename.Dir.t -> name_and_file list

(** Like {!opams_of_dir}, but changes the pinning_url if needed. If given [url]
    is local dir with vcs backend, and opam files not versioned, its pinning url
    is changed to rsync path-pin. If [ame_kind the_new_url] returns true,
    package information (name, opam file, new_url, subpath) are added to the
    returned list, otherwise it is discarded. *)
val opams_of_dir_w_target:
  ?locked:string -> ?recurse:bool -> ?subpath:subpath ->
  ?same_kind:(OpamUrl.t -> bool) -> OpamUrl.t -> OpamFilename.Dir.t ->
  name_and_file_w_url list

(** Resolves the opam files and directories in the list to package name and
    location, and returns the corresponding pinnings and atoms. May fail and
    exit if package names for provided [`Filename] could not be inferred, or if
    the same package name appears multiple times.
*)
val resolve_locals:
  ?quiet:bool -> ?locked:string -> ?recurse:bool -> ?subpath:subpath ->
  [ `Atom of atom | `Filename of filename | `Dirname of dirname ] list ->
  name_and_file_w_url list * atom list

(** Resolves the opam files and directories in the list to package name and
    location, according to what is currently pinned, and returns the
    corresponding list of atoms. Prints warnings for directories where nothing
    is pinned, or opam files corresponding to no pinned package.
*)
val resolve_locals_pinned:
  'a switch_state -> ?recurse:bool -> ?subpath:subpath ->
  [ `Atom of atom | `Dirname of dirname ] list ->
  atom list

(** Resolves the opam files in the list to package name and location, pins the
    corresponding packages accordingly if necessary, otherwise updates them, and
    returns the resolved atom list. With [simulate], don't do the pinnings but
    return the switch state with the package definitions that would have been
    obtained if pinning. Also synchronises the specified directories, that is,
    unpins any package pinned there but not current (no more corresponding opam
    file).

    This also handles [pin-depends:] of the local packages. That part is done
    even if [simulate] is [true].
*)
val autopin:
  rw switch_state ->
  ?simulate:bool ->
  ?quiet:bool ->
  ?locked:string ->
  ?recurse:bool ->
  ?subpath:subpath ->
  [ `Atom of atom | `Filename of filename | `Dirname of dirname ] list ->
  rw switch_state * atom list

(** The read-only version of [autopin ~simulate:true]: this doesn't require a
    write-locked switch, and doesn't update the local packages. [for_view] will
    result in the switch state containing more accurate information to be
    displayed to the user, but should never be flushed to disk because ; without
    that option, the state can safely be worked with and will just contain the
    proper package definitions *)
val simulate_autopin:
  'a switch_state ->
  ?quiet:bool ->
  ?for_view:bool ->
  ?locked:string ->
  ?recurse:bool ->
  ?subpath:subpath ->
  [ `Atom of atom | `Filename of filename | `Dirname of dirname ] list ->
  'a switch_state * atom list

(* Check sandboxing script call. If it errors or unattended output, disable
   sandboxing by removing {!OpamInitDefaults.sandbox_wrappers} commands in
   config file.
   Only one script is checked (init script default one), and tested on an
   `echo SUCCESS' call. *)
val check_and_revert_sandboxing:
  OpamPath.t -> OpamFile.Config.t -> OpamFile.Config.t
