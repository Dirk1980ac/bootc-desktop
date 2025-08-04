FROM quay.io/fedora/fedora-bootc:latest
ENV imagename="bootc-desktop"

# Install basic system
RUN <<END_OF_BLOCK
dnf -y --exclude=rootfiles --exclude=akmod\* \
	--exclude="virtualbox-guest-additions" \
	--setopt="install_weak_deps=False" install \
	@^workstation-product-environment usbutils

dnf -y install \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf -y install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
dnf -y --repo=rpmfusion-nonfree-tainted --repo=rpmfusion-free-tainted install "*-firmware"

END_OF_BLOCK

# Install non-GUI software
RUN dnf -y --exclude="virtualbox-guest-additions" install \
	cockpit \
	pass \
	fail2ban \
	dnf-bootc \
	mc \
	screen \
	yggdrasil \
	toolbox \
	waypipe \
	watchdog

# Install GUI software
RUN dnf -y install --setopt="install_weak_deps=False" \
	glibc-all-langpacks \
	calibre \
	digikam \
	evolution \
	filezilla \
	foliate \
	gimp \
	gnucash \
	libreoffice-langpack-de \
	mpv \
	snapshot \
	telegram-desktop \
	bootc-gtk \
	browserpass-*

# Install local packages (if available).
RUN --mount=type=bind,source=./packages,target=/packages  <<END_OF_BLOCK
set -eu
ARCH=$(arch)
shopt -s extglob
shopt -s nullglob

for file in /packages/*.@("${ARCH}".rpm|noarch.rpm); do
dnf -y install "$file"
done

END_OF_BLOCK

ARG buildid=unset

# Set Labels
LABEL org.opencontainers.image.vendor="Dirk Gottschalk" \
	org.opencontainers.image.authors="Dirk Gottschalk" \
	org.opencontainers.image.name=${imagename} \
	org.opencontainers.image.version=${buildid} \
	org.opencontainers.image.description="Custom desktop image"

# Copy prepared files
COPY --chmod=600 configs/ssh-00-0local.conf /etc/ssh/sshd_config.d/00-0local.conf
COPY --chmod=644 configs/rpm-ostreed.conf /etc/rpm-ostreed.conf
COPY --chmod=644 configs/watchdog.conf /etc/watchdog.conf
COPY --chmod=600 scripts/device-init.sh /usr/bin/device-init.sh
COPY --chmod=600 configs/sudoers-wheel /etc/sudoers.d/wheel
COPY --chmod=644 configs/dns-override.conf /usr/lib/systemd/resolved.conf.d/zz-local.conf
COPY --chmod=600 configs/jail-10-sshd.conf /etc/fail2ban/jail.d/10-sshd.conf
COPY --chmod=644 configs/dconf-user /usr/share/dconf/profile/user
COPY --chmod=644 configs/dconf-00-extensions /etc/dconf/db/local.d/00-extensions
COPY systemd /usr/lib/systemd/system
COPY skel /etc/skel

# Image signature settings
COPY --chmod=644 configs/registries-sigstore.yaml /usr/share/containers/registries.d/sigstore.yaml
COPY --chmod=644 configs/containers-toolbox.conf /etc/containers/toolbox.conf
COPY --chmod=644 configs/containers-policy.json /usr/share/containers/policy.json
COPY --chmod=644 keys /usr/share/containers/keys

# Final configuration
RUN <<END_OF_BLOCK
set -eu

chmod 755 /usr/share/containers/keys
rm -f /etc/containers/policy.json
rm -rf /etc/containers/registries.conf.d
ln -s /usr/share/containers/registries.d/sigstore.yaml /etc/containers/registries.d/sigstore.yaml
ln -s /usr/share/containers/policy.json /etc/containers/policy.json

dconf update

cat <<EOF >>/usr/lib/os-release
IMAGE_ID=${imagename}
IMAGE_VERSION=${buildid}
EOF

systemctl enable \
	cockpit.socket \
	sshd \
	systemd-zram-setup@zram0.service \
	device-init.service \
	bootc-fetch-update-only.timer \
	watchdog \
	fail2ban \
	bootloader-update.service

systemctl mask bootc-fetch-apply-updates.timer

dnf -y clean all
find /var/{log,cache} -type f ! -empty -delete
bootc container lint
END_OF_BLOCK
