source: http://www.securityfocus.com/bid/8827/info

Microsoft has reported the existence of a local buffer overrun vulnerability in an undisclosed User32.dll library function. This function is used by applications implementing the use of ListBox or ComboBox controls and will be triggered when the program encounters specific types of Windows messages.

This issue poses a security risk when a privileged application is running in the environment of an unprivileged user. Due to the ability for a program to transmit a windows message to another process, an attacker may be capable of exploiting this buffer overrun to gain privileged access to a system.

// vuln.cpp : Defines the entry point for the application.
//


#include "stdafx.h"
#include <windows.h>


LRESULT CALLBACK WndProc(HWND hwnd , UINT msg , WPARAM wp , LPARAM lp) {
	static HWND list;
	static HWND rich;

	switch (msg) {
	case WM_DESTROY:
		PostQuitMessage(0);
		return 0;
	case WM_CREATE:
		list = CreateWindow(
			TEXT("LISTBOX") , NULL , 
			WS_CHILD | WS_VISIBLE | LBS_STANDARD , 
			0 , 0 , 300 , 300 , hwnd , (HMENU)1 ,
			((LPCREATESTRUCT)(lp))->hInstance , NULL
		);
		rich = CreateWindow("EDIT",      // predefined class 
                                    NULL,        // no window title 
                                    WS_CHILD | WS_VISIBLE | WS_VSCROLL | 
                                    ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL, 
                                    300, 300, 100, 100,  // set size in WM_SIZE message 
                                    hwnd,        // parent window 
                                    (HMENU) 1,   // edit control ID 
                                    (HINSTANCE) GetWindowLong(hwnd, GWL_HINSTANCE), 
                                    NULL);  
		return 0;
	}
	return DefWindowProc(hwnd , msg , wp , lp);
}

int WINAPI WinMain(HINSTANCE hInstance , HINSTANCE hPrevInstance ,
			PSTR lpCmdLine , int nCmdShow ) {
	HWND hwnd;
	MSG msg;
	WNDCLASS winc;


	winc.style		= CS_HREDRAW | CS_VREDRAW;
	winc.lpfnWndProc	= WndProc;
	winc.cbClsExtra	= winc.cbWndExtra	= 0;
	winc.hInstance		= hInstance;
	winc.hIcon		= LoadIcon(NULL , IDI_APPLICATION);
	winc.hCursor		= LoadCursor(NULL , IDC_ARROW);
	winc.hbrBackground	= (HBRUSH)GetStockObject(WHITE_BRUSH);
	winc.lpszMenuName	= NULL;
	winc.lpszClassName	= TEXT("KITTY");

	if (!RegisterClass(&winc)) return -1;

	hwnd = CreateWindow(
			TEXT("KITTY") , TEXT("Kitty on your lap") ,
			WS_OVERLAPPEDWINDOW | WS_VISIBLE ,
			CW_USEDEFAULT , CW_USEDEFAULT ,
			CW_USEDEFAULT , CW_USEDEFAULT ,
			NULL , NULL , hInstance , NULL
	);

	if (hwnd == NULL) return -1;

	while(GetMessage(&msg , NULL , 0 , 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	return msg.wParam;
}