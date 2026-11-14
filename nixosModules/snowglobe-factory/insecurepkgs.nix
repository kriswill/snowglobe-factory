# list of permitted insecure packages in nixpkgs.
{
	 nixpkgs.config.permittedInsecurePackages = [
		# TODO qutebrowser accepts compromised certs from emudhra.
		"qutebrowser-3.7.0"
	];
}
