## Plan: Make Stata Paths Portable

Many scripts point to a folder on someone else’s computer. Following Box 2.4, I’d set the project location and name the existing data and output folders in one place, then update the scripts to use those names. The folders and analysis steps will stay as they are.

**Steps**
1. Add a Stata setup file that sets the project location for your computer and gives names to the existing folders.
2. Update the scripts to use those names instead of the old computer’s location. Run the setup file before running the analysis scripts.
3. Make the RAIS data location configurable, since those files are stored outside this project.
4. Update the README with setup instructions, script order, and the external files needed.

**Checks**
- Search for any old computer-specific paths left in the scripts.
- Confirm the scripts still use the same data and output folders.
- If Stata and the required data are available, run sample scripts from each method after running the setup file.

I’ll keep the current folders and won’t move any data. No project files have been changed.