FROM registry.fedoraproject.org/fedora-bootc:latest
ENV imagename="bootc-desktop"

# Install basic system
RUN dnf -y --exclude=rootfiles --exclude=akmod\* \
	--setopt="install_weak_deps=False" install \
	@^workstation-product-environment usbutils && dnf -y clean all

# Install additional packages and do other neccessary stuff.
RUN --mount=type=bind,source=./packages,target=/packages <<END_OF_BLOCK
set -eu

dnf -y install \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf -y install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
dnf -y --repo=rpmfusion-nonfree-tainted --repo=rpmfusion-free-tainted install "*-firmware"

dnf -y install --setopt="install_weak_deps=False" \
	glibc-all-langpacks \
	watchdog \
	calibre \
	cockpit \
	digikam \
	evolution \
	filezilla \
	foliate \
	gimp \
	gnucash \
	libreoffice-langpack-de \
	smplayer  \
	snapshot \
	telegram-desktop \
	toolbox \
	waypipe \
	yggdrasil \
	mc \
	screen \
	dnf-bootc \
	bootc-gtk

ARCH=$(arch)
shopt -s extglob
shopt -s nullglob

for file in /packages/*.@(${ARCH}.rpm|noarch.rpm); do
	dnf -y install "$file"
done

dnf -y clean all
END_OF_BLOCK

ARG buildid=unset

# Set Labels
LABEL org.opencontainers.image.vendor="Dirk Gottschalk" \
	org.opencontainers.image.authors="Dirk Gottschalk" \
	org.opencontainers.image.name=${imagemame} \
	org.opencontainers.image.version=${buildid} \
	org.opencontainers.image.description="Custom desktop image"

# Copy prepared files
COPY --chmod=600 configs/ssh-00-0local.conf /etc/ssh/sshd_config.d/00-0local.conf
COPY --chmod=644 configs/rpm-ostreed.conf /etc/rpm-ostreed.conf
COPY --chmod=644 configs/watchdog.conf /etc/watchdog.conf
COPY --chmod=600 scripts/device-init.sh /usr/bin/device-init.sh
COPY --chmod=600 configs/sudoers-wheel /etc/sudoers.d/wheel
COPY --chmod=644 configs/dns-override.conf /usr/lib/systemd/resolved.conf.d/zz-local.conf
COPY systemd /usr/lib/systemd/system

# Image signature settings
COPY --chmod=644 configs/registries-sigstore.yaml /etc/containers/registries.d/sigstore.yaml
COPY --chmod=644 configs/containers-toolbox.conf /etc/containers/toolbox.conf
COPY --chmod=644 configs/containers-policy.json /etc/containers/policy.json
COPY --chmod=644 keys /usr/share/containers/keys

RUN <<END_OF_BLOCK
set -eu
chmod 755 /usr/share/containers/keys
echo "IMAGE_ID=${imagename}" >>/usr/lib/os-release
echo "IMAGE_VERSION=${buildid}" >>/usr/lib/os-release

systemctl enable \
	cockpit.socket \
	sshd \
	systemd-zram-setup@zram0.service \
	device-init.service \
	bootc-fetch-update-only.timer \
	watchdog \
	bootloader-update.service

systemctl mask bootc-fetch-apply-updates.timer
find /var/{log,cache} -type f ! -empty -delete
bootc container lint
END_OF_BLOCK
