import platform, zipfile, subprocess, urllib.request


mcr_url = {
   "Windows" : "http://ssd.mathworks.com/supportfiles/downloads/R2018b/deployment_files/R2018b/installers/win64/MCR_R2018b_win64_installer.exe",
   "Darwin": "http://ssd.mathworks.com/supportfiles/downloads/R2018b/deployment_files/R2018b/installers/maci64/MCR_R2018b_maci64_installer.dmg.zip",
   "Linux": "http://ssd.mathworks.com/supportfiles/downloads/R2018b/deployment_files/R2018b/installers/glnxa64/MCR_R2018b_glnxa64_installer.zip"
}

mcr_name = {
   "Windows" : "mcr.exe",
   "Darwin": "mcr.dmg.zip",
   "Linux": "mcr.zip"
}

mcr_command = {
   "Windows": "setup -mode silent -agreeToLicense yes",
   "Darwin":  "./install -mode silent -agreeToLicense yes",
   "Linux": "./install -mode silent -agreeToLicense yes"
}

system = platform.system()

url = mcr_url[system]
filename = mcr_name[system]
command = mcr_command[system]

print(" - Downloading: " + url)
urllib.request.urlretrieve(url, filename)

print(" - Extracting: " + filename + " to 'mcr'")
zip = zipfile.ZipFile(filename, 'r')
zip.extractall('mcr')

print(" - Installing MCR")
subprocess.run(command.split(" "), check=True, cwd='mcr')
