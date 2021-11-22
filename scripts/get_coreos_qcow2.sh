# exit on error
set -e

# download newest stable json
curl -O "https://builds.coreos.fedoraproject.org/streams/stable.json" &> /dev/null
if [[ ! -f stable.json ]]; then
	echo "stable.json not found"
	exit 1
fi 

# get qemu qcow2 info
obj=$(jq -r '.architectures.x86_64.artifacts.qemu.formats."qcow2.xz".disk'  stable.json)
echo image: $obj
# payload url
location=$(jq -r '.location' <<< "$obj")
echo location $location
# sig url
sig=$(jq -r '.signature' <<< "$obj")
# hash
sha=$(jq -r '.sha256' <<< "$obj")
echo hash: $sha

# download payload
echo "downloading: $(basename $location)"
curl -O $location &> /dev/null
echo "finished downloading"
curl -O $sig &> /dev/null
echo "downloaded signiture"

gpg --verify $(basename $sig)
echo "$sha $(basename $location)" | sha256sum -c
echo -e "\nHash and signature okay"

# unpack and rename
unxz -k $(basename $location)
echo unpacked archive
#fname=$(basename $location)
#mv ${fname%.*} fedora-coreos.x86_64.qcow2
