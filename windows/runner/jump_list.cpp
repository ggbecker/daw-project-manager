#include "jump_list.h"

#include <windows.h>
#include <shobjidl.h>
#include <propkey.h>
#include <propvarutil.h>

bool UpdateJumpList(
    const std::vector<std::pair<std::wstring, std::wstring>>& projects) {
  ICustomDestinationList* pDL = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_DestinationList, nullptr,
                                 CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pDL));
  if (FAILED(hr)) return false;

  UINT uMinSlots = 0;
  IObjectArray* pRemoved = nullptr;
  hr = pDL->BeginList(&uMinSlots, IID_PPV_ARGS(&pRemoved));
  if (pRemoved) pRemoved->Release();
  if (FAILED(hr)) { pDL->Release(); return false; }

  IObjectCollection* pCol = nullptr;
  hr = CoCreateInstance(CLSID_EnumerableObjectCollection, nullptr,
                        CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pCol));
  if (FAILED(hr)) { pDL->AbortList(); pDL->Release(); return false; }

  for (const auto& [name, path] : projects) {
    IShellLink* pLink = nullptr;
    if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&pLink))))
      continue;

    pLink->SetPath(path.c_str());
    pLink->SetDescription(name.c_str());

    // Set the display title shown in the jump list
    IPropertyStore* pPS = nullptr;
    if (SUCCEEDED(pLink->QueryInterface(IID_PPV_ARGS(&pPS)))) {
      PROPVARIANT pv;
      if (SUCCEEDED(InitPropVariantFromString(name.c_str(), &pv))) {
        pPS->SetValue(PKEY_Title, pv);
        PropVariantClear(&pv);
      }
      pPS->Commit();
      pPS->Release();
    }

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
