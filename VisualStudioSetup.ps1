###List installed extensions###

code --extensions-dir --list-extensions

###Install visual studio code extensions.
code --install-extension ms-vscode.powershell
code --install-extension ms-mssql.mssql
code --install-extension robertohuertasm.vscode-icons
code --install-extension msazurermtools.azurerm-vscode-tools
code --install-extension ms-vscode.azurecli

###unInstall visual studio code extensions.
code --uninstall-extension msazurermtools.azurerm-vscode-tools
code --uninstall-extension ms-vscode.powershell
code --uninstall-extension ms-mssql.mssql
code --uninstall-extension robertohuertasm.vscode-icons


##Setup icons##
# Press F1 --> preferences: file icon Theme --> vscode icons

##Switch Language for file##
#CTRL + K and then press M


#install Git
explorer https://github.com/git-for-windows/git/releases/download/v2.20.0.windows.1/Git-2.20.0-64-bit.exe

#Clone repository from Github
#CTRL + Shift + P --> git: Clone --> Enter repository you would like to Clone --> enter destination.

#Configure Git
#Open "Git CMD" --> run the following commands:

#git config --global user.email "you@example.com"
#git config --global user.name "Your Name"

yrdyrt