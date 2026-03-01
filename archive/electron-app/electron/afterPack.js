const { execSync } = require("child_process");
const path = require("path");
const fs = require("fs");

exports.default = async function (context) {
  const appPath = path.join(context.appOutDir, `${context.packager.appInfo.productFilename}.app`);
  console.log(`Stripping resource forks from: ${appPath}`);

  // Remove all extended attributes recursively
  execSync(`xattr -rc "${appPath}"`, { stdio: "inherit" });

  // Clean up ._* resource fork files
  execSync(`dot_clean "${appPath}" 2>/dev/null || true`, { stdio: "inherit" });

  // Belt-and-suspenders: find and delete any remaining ._ files
  execSync(`find "${appPath}" -name '._*' -delete 2>/dev/null || true`, { stdio: "inherit" });

  // Strip xattrs one more time after dot_clean
  execSync(`xattr -rc "${appPath}"`, { stdio: "inherit" });
};
