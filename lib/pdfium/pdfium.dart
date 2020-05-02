library pdfium;

import 'dart:ffi';

import 'dart:io';
import 'functions.dart';

export 'functions.dart';
export 'structs.dart';

void loadDylib(String path) {
  // var dylib = ffi.DynamicLibrary.open(path);
  final DynamicLibrary dylib = Platform.isAndroid
      ? DynamicLibrary.open("libpdfsdk.so")
      : DynamicLibrary.open("rPPG.framework/rPPG");
  fInitLibraryWithConfig =
      dylib.lookupFunction<FPDF_InitLibraryWithConfig, InitLibraryWithConfig>(
    "FPDF_InitLibraryWithConfig",
  );
  fDestroyLibrary = dylib.lookupFunction<FPDF_DestroyLibrary, DestroyLibrary>(
    "FPDF_DestroyLibrary",
  );
  fLoadDocument = dylib.lookupFunction<FPDF_LoadDocument, FPDF_LoadDocument>(
    "FPDF_LoadDocument",
  );
  fGetLastError = dylib.lookupFunction<FPDF_GetLastError, GetLastError>(
    "FPDF_GetLastError",
  );
  fCloseDocument = dylib.lookupFunction<FPDF_CloseDocument, CloseDocument>(
    "FPDF_CloseDocument",
  );
  fGetPageCount = dylib.lookupFunction<FPDF_GetPageCount, GetPageCount>(
    "FPDF_GetPageCount",
  );
  fLoadPage = dylib.lookupFunction<FPDF_LoadPage, LoadPage>(
    "FPDF_LoadPage",
  );
  fBitmapCreate = dylib.lookupFunction<FPDFBitmap_Create, BitmapCreate>(
    "FPDFBitmap_Create",
  );
  fRenderPageBitmap =
      dylib.lookupFunction<FPDF_RenderPageBitmap, RenderPageBitmap>(
    "FPDF_RenderPageBitmap",
  );
  fGetPageHeight = dylib.lookupFunction<FPDF_GetPageHeight, GetPageHeight>(
    "FPDF_GetPageHeight",
  );
  fGetPageWidth = dylib.lookupFunction<FPDF_GetPageWidth, GetPageWidth>(
    "FPDF_GetPageWidth",
  );
  fBitmapFillRect = dylib.lookupFunction<FPDFBitmap_FillRect, BitmapFillRect>(
    "FPDFBitmap_FillRect",
  );
  fBitmapGetBuffer =
      dylib.lookupFunction<FPDFBitmap_GetBuffer, BitmapGetBuffer>(
    "FPDFBitmap_GetBuffer",
  );
  fPageSetRotation =
      dylib.lookupFunction<FPDFPage_SetRotation, PageSetRotation>(
    "FPDFPage_SetRotation",
  );
  fTextLoadPage = dylib.lookupFunction<FPDFText_LoadPage, TextLoadPage>(
    "FPDFText_LoadPage",
  );
  fTextClosePage = dylib.lookupFunction<FPDFText_ClosePage, TextClosePage>(
    "FPDFText_ClosePage",
  );
  fTextGetText = dylib.lookupFunction<FPDFText_GetText, TextGetText>(
    "FPDFText_GetText",
  );
  fAnnotIsSupportedSubtype = dylib
      .lookupFunction<FPDFAnnot_IsSupportedSubtype, AnnotIsSupportedSubtype>(
    "FPDFAnnot_IsSupportedSubtype",
  );
  fTextGetUnicode = dylib.lookupFunction<FPDFText_GetUnicode, TextGetUnicode>(
      "FPDFText_GetUnicode");
  fTextCountChars = dylib.lookupFunction<FPDFText_CountChars,TextCountChars>("FPDFText_CountChars");
}

num pointsToPixels(num points, num ppi) {
  return points / 72 * ppi;
}
