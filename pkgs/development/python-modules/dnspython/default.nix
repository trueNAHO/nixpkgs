{ lib
, stdenv
, buildPythonPackage
, fetchPypi
, pythonOlder
, setuptools-scm
, pytestCheckHook
, cacert
}:

buildPythonPackage rec {
  pname = "dnspython";
  version = "2.3.0";
  format = "setuptools";

  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit pname version;
    extension = "tar.gz";
    hash = "sha256-Ik4ysD60a+cOEu9tZOC+Ejpk5iGrTAgi/21FDVKlQLk=";
  };

  nativeCheckInputs = [
    pytestCheckHook
  ] ++ lib.optionals stdenv.isDarwin [
    cacert
  ];

  disabledTests = [
    # dns.exception.SyntaxError: protocol not found
    "test_misc_good_WKS_text"
    # fails if IPv6 isn't available
    "test_resolver_override"

  # Tests that run inconsistently on darwin systems
  ] ++ lib.optionals stdenv.isDarwin [
    # 9 tests fail with: BlockingIOError: [Errno 35] Resource temporarily unavailable
    "testQueryUDP"
    # 6 tests fail with: dns.resolver.LifetimeTimeout: The resolution lifetime expired after ...
    "testResolveCacheHit"
    "testResolveTCP"
  ];

  nativeBuildInputs = [
    setuptools-scm
  ];

  pythonImportsCheck = [
    "dns"
  ];

  meta = with lib; {
    description = "A DNS toolkit for Python";
    homepage = "https://www.dnspython.org";
    changelog = "https://github.com/rthalley/dnspython/blob/v${version}/doc/whatsnew.rst";
    license = with licenses; [ isc ];
    maintainers = with maintainers; [ gador ];
  };
}
