{ stdenv, fetchurl, meson, ninja, pkgconfig, gettext, gnome3, dbus
, glib, libgudev, udisks2, libgcrypt, libcap, polkit
, libgphoto2, avahi, libarchive, fuse, libcdio
, libxml2, libxslt, docbook_xsl, docbook_xml_dtd_42, samba, libmtp
, gnomeSupport ? false, gnome, makeWrapper, gcr
, libimobiledevice, libbluray, libcdio-paranoia, libnfs, openssh
, libsecret, libgdata, python3
}:

let
  pname = "gvfs";
  version = "1.38.1";
in stdenv.mkDerivation rec {
  name = "${pname}-${version}";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${stdenv.lib.versions.majorMinor version}/${name}.tar.xz";
    sha256 = "18311pn5kp9b4kf5prvhcjs0cwf7fm3mqh6s6p42avcr5j26l4zd";
  };

  postPatch = ''
    # patchShebangs requires executable file
    chmod +x codegen.py meson_post_install.py
    patchShebangs meson_post_install.py
    patchShebangs codegen.py
    patchShebangs test test-driver
  '';

  nativeBuildInputs = [
    meson ninja python3
    pkgconfig gettext makeWrapper
    libxml2 libxslt docbook_xsl docbook_xml_dtd_42
  ];

  buildInputs = [
    glib libgudev udisks2 libgcrypt dbus
    libgphoto2 avahi libarchive fuse libcdio
    samba libmtp libcap polkit libimobiledevice libbluray
    libcdio-paranoia libnfs openssh
    # ToDo: a ligther version of libsoup to have FTP/HTTP support?
  ] ++ stdenv.lib.optionals gnomeSupport (with gnome; [
    libsoup gcr
    gnome-online-accounts libsecret libgdata
  ]);

  mesonFlags = [
    "-Dsystemduserunitdir=${placeholder "out"}/lib/systemd/user"
    "-Dtmpfilesdir=no"
  ] ++ stdenv.lib.optionals (!gnomeSupport) [
    "-Dgcr=false" "-Dgoa=false" "-Dkeyring=false" "-Dhttp=false"
    "-Dgoogle=false"
  ] ++ stdenv.lib.optionals (samba == null) [
    # Xfce don't want samba
    "-Dsmb=false"
  ];

  doCheck = false; # fails with "ModuleNotFoundError: No module named 'gi'"
  doInstallCheck = doCheck;

  preFixup = ''
    for f in $out/libexec/*; do
      wrapProgram $f \
        ${stdenv.lib.optionalString gnomeSupport "--prefix GIO_EXTRA_MODULES : \"${stdenv.lib.getLib gnome.dconf}/lib/gio/modules\""} \
        --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
    done
  '';

  passthru = {
    updateScript = gnome3.updateScript {
      packageName = pname;
    };
  };

  meta = with stdenv.lib; {
    description = "Virtual Filesystem support library" + optionalString gnomeSupport " (full GNOME support)";
    license = licenses.lgpl2Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.lethalman ] ++ gnome3.maintainers;
  };
}
