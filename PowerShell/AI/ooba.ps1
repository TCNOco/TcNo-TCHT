# Copyright (C) 2023 TroubleChute (Wesley Pyburn)
# Licensed under the GNU General Public License v3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.en.html
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ----------------------------------------
# I don't like nesting functions, but as this is used by other installers, I need to...
# Visit Install-Ooba.tc.ht for the function code.
# ----------------------------------------
Write-Host "Welcome to TroubleChute's Oobabooga installer!" -ForegroundColor Cyan
Write-Host "Oobabooga should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-18]`n`n" -ForegroundColor Cyan

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-FunctionIfNotExists -Command Install-Ooba -ScriptUri "Install-Ooba.tc.ht"

Install-Ooba