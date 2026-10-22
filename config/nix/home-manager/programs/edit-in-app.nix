{ lib, ... }: {
  # macOS only looks for services in ~/Library/Services, and it is not XDG-aware.
  #
  # The bundles have to be real files rather than links into the store. With
  # home.file's symlinks a sandboxed app (Mail, Safari) lists the service but
  # invoking it does nothing at all -- no error anywhere -- and copying the same
  # bundle in as regular files makes it work. So copy them, after home-manager is
  # done linking, and flush the cache pbs keeps of the Services list.
  home.activation.editInAppServices = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run mkdir -p "$HOME/Library/Services"
    for bundle in ${../../../services}/*.workflow; do
      target="$HOME/Library/Services/$(basename "$bundle")"
      run rm -rf "$target"
      run cp -RL "$bundle" "$target"
      run chmod -R u+rwX "$target"
    done
    run /System/Library/CoreServices/pbs -flush
  '';
}
