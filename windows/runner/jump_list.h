#ifndef RUNNER_JUMP_LIST_H_
#define RUNNER_JUMP_LIST_H_

#include <string>
#include <vector>

// Rebuilds the Windows taskbar Jump List (right-click menu): a static
// "Tasks" section (New Project, Scan for Projects) plus a "Recent Projects"
// category. Every entry relaunches this same exe with a command-line
// argument (--new-project / --scan-projects / --open-project=<id>) that
// main.dart interprets — either at cold start or by forwarding it to an
// already-running instance over the single-instance loopback socket.
// projects = vector of {displayName, id}
bool UpdateJumpList(
    const std::vector<std::pair<std::wstring, std::wstring>>& projects);

#endif  // RUNNER_JUMP_LIST_H_
