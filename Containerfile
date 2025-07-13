FROM registry.fedoraproject.org/fedora-bootc:latest

ENV imagename="bootc-desktop"
ARG buildid=unset

# Set Labels
LABEL org.opencontainers.image.vendor="Dirk Gottschalk" \
	org.opencontainers.image.name=${imagemame} \
	org.opencontainers.image.version=${buildid} \
	org.opencontainers.image.description="Experimental custom desktop image"

# Install basic system
RUN dnf -y --exclude=rootfiles --exclude=akmod\* install \
	@^workstation-product-environment

# Copy prepared files
COPY --chown=root:root scripts /usr/local/bin
COPY --chown=root:root configs /etc
COPY --chown=root:root systemd /usr/lib/systemd

# Install additional packages and do other neccessary stuff.
RUN <<END_OF_BLOCK
set -eu

echo "Add and enable RPMFusion repos install nasty things like evil (proptietary) codecs."
dnf -y install \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf -y install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

dnf -y --repo=rpmfusion-nonfree-tainted install "*-firmware"

echo "Do the really dirty deed!"
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

echo "Cleaning up."
dnf -y clean all

echo "Writing image version information"
echo "IMAGE_ID=${imagename}" >>/usr/lib/os-release
echo "IMAGE_VERSION=${buildid}" >>/usr/lib/os-release

echo "Enable services."
systemctl enable \
	cockpit.socket \
	sshd \
	systemd-zram-setup@zram0.service \
	device-init.service \
	bootc-fetch-update-only.timer \
	watchdog

echo "Masking default update timer because it instantly reboots after update."
systemctl mask bootc-fetch-apply-updates.timer

rm /var/{log,account,cache,spool}/* -rf
bootc container lint
echo "The magic is done!"
END_OF_BLOCK
