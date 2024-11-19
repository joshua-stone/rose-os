#!/bin/sh

set -oeu pipefail

readonly REGISTRY="${1:-ghcr.io/joshua-stone}"
readonly ORG="${2:-rose-os}"
readonly FLAVOR="${3:-silverblue}"
readonly TAG="${4:-latest}"
readonly ARCH="${5:-x86_64}"
readonly RELEASE="${6:-41}"
readonly IMAGE="${REGISTRY}/${ORG}-${FLAVOR}:${TAG}"
readonly IMAGE_DIR="${REGISTRY}/${ORG}-${FLAVOR}-${TAG}"
readonly ISO_BUILD_NAME="${ORG}-${FLAVOR}-${RELEASE}-${ARCH}"

readonly RELEASE_TYPE="releases"
readonly OUTFILE="installer.iso"


readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

readonly BUILD_DIR="${SCRIPT_DIR}/build"
readonly ISO_DIR="${BUILD_DIR}/iso"
readonly OCI_DIR="${BUILD_DIR}/oci"
readonly OCI_TAG_DIR="${OCI_DIR}/tags"
readonly OCI_REF_DIR="${OCI_DIR}/refs"

if [[ -d "${BUILD_DIR}" ]]; then
    echo "Directory '$BUILD_DIR/' already exists. Running 'rm -rf ${BUILD_DIR}/' may be recommended"
fi

mkdir --verbose --parents "${ISO_DIR}" "${OCI_TAG_DIR}" "${OCI_REF_DIR}"

cd "${ISO_DIR}"

wget --continue \
     --no-parent \
     --no-directories \
     --recursive \
     --accept-regex "Fedora-Everything-(netinst-${ARCH}-${RELEASE}-.*.iso|${RELEASE}-.*-${ARCH}-CHECKSUM)$" \
     "https://dl.fedoraproject.org/pub/fedora/linux/${RELEASE_TYPE}/${RELEASE}/Everything/${ARCH}/iso/"


if [[ "$(ls -1q *-CHECKSUM | wc -l)" -ne 1 || "$(ls -1q *.iso | wc -l)" -ne 1 ]]; then
    echo "Too many checksums and/or ISOs detected. Exiting now."
    exit 1
fi

sha256sum --check Fedora-Everything*-CHECKSUM

cd -

readonly IMAGE_METADATA="$(podman inspect "${IMAGE}")"

readonly IMAGE_OSTREE_VERSION="$(echo "${IMAGE_METADATA}" | jq -r '.[]["Labels"]["org.opencontainers.image.version"]')"
readonly IMAGE_ID="$(echo "${IMAGE_METADATA}" | jq -r '.[].Id[:12]')"

if [[ -f "${OCI_REF_DIR}/${IMAGE_ID}/index.json" && -f "${OCI_REF_DIR}/${IMAGE_ID}/oci-layout" && -d ${OCI_REF_DIR}/${IMAGE_ID}/blobs ]]; then
    echo "Image already downloaded: ${OCI_REF_DIR}/${IMAGE_ID}"
else
    rm -rf "${OCI_REF_DIR}/${IMAGE_ID}"
    podman save --format="oci-dir" --output="${OCI_REF_DIR}/${IMAGE_ID}" "${IMAGE}"
fi

rm -rf "${OCI_TAG_DIR}/${ORG}-${FLAVOR}-${TAG}"

ln -sv "../refs/${IMAGE_ID}/" "${OCI_TAG_DIR}/${ORG}-${FLAVOR}-${TAG}"

readonly OUTPUT_DIR="${BUILD_DIR}/output/${ISO_BUILD_NAME}"

mkdir --verbose --parents "${OUTPUT_DIR}/kickstart/oci/${REGISTRY}" 

rm -rf "${OUTPUT_DIR}/kickstart/oci/${IMAGE_DIR}"

cp --verbose --recursive --link "${OCI_REF_DIR}/${IMAGE_ID}" "${OUTPUT_DIR}/kickstart/oci/${IMAGE_DIR}"

cat << EOL > "${OUTPUT_DIR}/kickstart/kickstart-env-vars"
REGISTRY="${REGISTRY}"
ORG="${ORG}"
FLAVOR="${FLAVOR}"
ARCH="${ARCH}"
TAG="${TAG}"
RELEASE="${RELEASE}"
EOL

readonly FLATPAK_REMOTE_DIR="${OUTPUT_DIR}/kickstart/flatpak/remotes"

rm -rf "${OUTPUT_DIR}/kickstart/flatpak"
mkdir --verbose --parents "${FLATPAK_REMOTE_DIR}"

curl -s https://dl.flathub.org/repo/flathub.flatpakrepo --output "${FLATPAK_REMOTE_DIR}/flathub.flatpakrepo"

readonly OUTPUT_ISO="${OUTPUT_DIR}/${ORG}-${FLAVOR}-${IMAGE_OSTREE_VERSION}-${ARCH}.iso"

rm -rf "${OUTPUT_ISO}"

sudo mkksiso --ks anaconda-ks.cfg \
	     --add "${OUTPUT_DIR}/kickstart" \
	     ${ISO_DIR}/Fedora-Everything-netinst*.iso \
	     "${OUTPUT_ISO}"

sudo chown "${USER}:${USER}" "${OUTPUT_ISO}"
