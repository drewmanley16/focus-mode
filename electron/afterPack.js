const { execSync } = require("child_process");
const path = require("path");

exports.default = async function (context) {
  const appPath = path.join(context.appOutDir, `${context.packager.appInfo.productFilename}.app`);
  console.log(`Stripping resource forks from: ${appPath}`);
  execSync(`xattr -cr "${appPath}"`, { stdio: "inherit" });
};
