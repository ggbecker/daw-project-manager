#ifndef RUNNER_JUMP_LIST_H_
#define RUNNER_JUMP_LIST_H_

#include <string>
#include <vector>

// Updates the Windows taskbar Jump List (right-click menu) with the supplied
// projects. Each item opens the project file with its default application.
// projects = vector of {displayName, filePath}
bool UpdateJumpList(
    const std::vector<std::pair<std::wstring, std::wstring>>& projects);

#endif  // RUNNER_JUMP_LIST_H_
