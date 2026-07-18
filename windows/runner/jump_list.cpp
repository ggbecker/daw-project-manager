#include "jump_list.h"

#include <windows.h>
#include <shobjidl.h>
#include <propkey.h>
#include <propvarutil.h>

namespace {

// Builds a shell link that relaunches this same exe with the given
// command-line argument, reusing the exe's own icon.
IShellLink* MakeSelfLink(const std::wstring& exePath,
                         const std::wstring& title,
                         const std::wstring& args) {
  IShellLink* pLink = nullptr;
  if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                              IID_PPV_ARGS(&pLink))))
    return nullptr;

  pLink->SetPath(exePath.c_str());
  pLink->SetArguments(args.c_str());
  pLink->SetIconLocation(exePath.c_str(), 0);
  pLink->SetDescription(title.c_str());

  IPropertyStore* pPS = nullptr;
  if (SUCCEEDED(pLink->QueryInterface(IID_PPV_ARGS(&pPS)))) {
    PROPVARIANT pv;
    if (SUCCEEDED(InitPropVariantFromString(title.c_str(), &pv))) {
      pPS->SetValue(PKEY_Title, pv);
      PropVariantClear(&pv);
    }
    pPS->Commit();
    pPS->Release();
  }

  return pLink;
}

}  // namespace

bool UpdateJumpList(
    const std::vector<std::pair<std::wstring, std::wstring>>& projects) {
  wchar_t exePathBuf[MAX_PATH];
  if (GetModuleFileNameW(nullptr, exePathBuf, MAX_PATH) == 0) return false;
  std::wstring exePath(exePathBuf);

  ICustomDestinationList* pDL = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_DestinationList, nullptr,
                                 CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pDL));
  if (FAILED(hr)) return false;

  UINT uMinSlots = 0;
  IObjectArray* pRemoved = nullptr;
  hr = pDL->BeginList(&uMinSlots, IID_PPV_ARGS(&pRemoved));
  if (pRemoved) pRemoved->Release();
  if (FAILED(hr)) { pDL->Release(); return false; }

  // ── Tasks: static quick actions ─────────────────────────────────────────
  IObjectCollection* pTasks = nullptr;
  if (SUCCEEDED(CoCreateInstance(CLSID_EnumerableObjectCollection, nullptr,
                                 CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pTasks)))) {
    if (auto* link = MakeSelfLink(exePath, L"New Project", L"--new-project")) {
      pTasks->AddObject(link);
      link->Release();
    }
    if (auto* link = MakeSelfLink(exePath, L"Scan for Projects", L"--scan-projects")) {
      pTasks->AddObject(link);
      link->Release();
    }
    IObjectArray* pTaskArr = nullptr;
    if (SUCCEEDED(pTasks->QueryInterface(IID_PPV_ARGS(&pTaskArr)))) {
      pDL->AddUserTasks(pTaskArr);
      pTaskArr->Release();
    }
    pTasks->Release();
  }

  // ── Category: recent projects (opens in-app, not the raw DAW file) ─────
  IObjectCollection* pCol = nullptr;
  hr = CoCreateInstance(CLSID_EnumerableObjectCollection, nullptr,
                        CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pCol));
  if (FAILED(hr)) { pDL->AbortList(); pDL->Release(); return false; }

  for (const auto& [name, id] : projects) {
    IShellLink* pLink =
        MakeSelfLink(exePath, name, L"--open-project=" + id);
    if (!pLink) continue;
    pCol->AddObject(pLink);
    pLink->Release();
  }

  IObjectArray* pArr = nullptr;
  if (SUCCEEDED(pCol->QueryInterface(IID_PPV_ARGS(&pArr)))) {
    pDL->AppendCategory(L"Recent Projects", pArr);
    pArr->Release();
  }
  pCol->Release();

  pDL->CommitList();
  pDL->Release();
  return true;
}
