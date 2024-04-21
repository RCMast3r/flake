{ lib, stdenv, fetchurl, unzip }:
# shoutout to this dude: https://nono.ma/download-dropbox-file-curl
stdenv.mkDerivation rec {
  name = "groundtruths";
  dontUnpack = true;
  dontFixup = true;
  buildInputs = [ unzip ];
  src = fetchurl {
    url = "https://www.dropbox.com/scl/fo/h42wt4t2k9ize3bleztlp/h/Prompting%20results.zip?rlkey=s7zs8j9gcu3fgik05490oqjvl&dl=1";
    curlOptsList = [ "-L" ];
    sha256 = "sha256-Fr5uXLG8zzyUM3g7i/KMfNiVKddvQwebFOj9odMwVcw=";
  };
  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    unzip ${src} -d $out -x /
    unzip $out/*.zip -d $out
    # Function to safely rename files and directories
    rename_safely() {
        local old_path="$1"
        local dirname="$(dirname "$old_path")"
        local basename="$(basename "$old_path")"
        local new_basename="$(echo "$basename" | tr ' ' '_')"

        # Check if the new name differs from the old name
        if [[ "$basename" != "$new_basename" ]]; then
            local new_path="$dirname/$new_basename"
            # Check if a file/directory with the new name already exists
            if [[ -e "$new_path" ]]; then
                echo "Error: '$new_path' already exists. Skipping '$old_path'."
            else
                mv -- "$old_path" "$new_path"
                echo "Renamed '$old_path' to '$new_path'"
            fi
        fi
    }

    export -f rename_safely

    # Find all directories and files with spaces in their names, starting from the deepest level
    find $out -depth -name "* *" -exec bash -c 'rename_safely "$0"' {} \;
  '';

}
