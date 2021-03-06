// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"

#include <QuartzCore/CALayer.h>

#include <memory>

#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/trace_event.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

namespace shell {

IOSSurfaceSoftware::IOSSurfaceSoftware(PlatformView::SurfaceConfig surface_config, CALayer* layer)
    : IOSSurface(surface_config, layer) {
  UpdateStorageSizeIfNecessary();
}

IOSSurfaceSoftware::~IOSSurfaceSoftware() = default;

bool IOSSurfaceSoftware::IsValid() const {
  return GetLayer() != nullptr;
}

bool IOSSurfaceSoftware::ResourceContextMakeCurrent() {
  return false;
}

void IOSSurfaceSoftware::UpdateStorageSizeIfNecessary() {
  // Nothing to do here. We don't need an external entity to tell us when our
  // backing store needs to be updated. Instead, we let the frame tell us its
  // size so we can update to match. This method was added to work around
  // Android oddities.
}

std::unique_ptr<Surface> IOSSurfaceSoftware::CreateGPUSurface() {
  if (!IsValid()) {
    return nullptr;
  }

  auto surface = std::make_unique<GPUSurfaceSoftware>(this);

  if (!surface->IsValid()) {
    return nullptr;
  }

  return surface;
}

sk_sp<SkSurface> IOSSurfaceSoftware::AcquireBackingStore(const SkISize& size) {
  TRACE_EVENT0("flutter", "IOSSurfaceSoftware::AcquireBackingStore");
  if (!IsValid()) {
    return nullptr;
  }

  if (sk_surface_ != nullptr &&
      SkISize::Make(sk_surface_->width(), sk_surface_->height()) == size) {
    // The old and new surface sizes are the same. Nothing to do here.
    return sk_surface_;
  }

  sk_surface_ = SkSurface::MakeRasterN32Premul(size.fWidth, size.fHeight,
                                               nullptr /* SkSurfaceProps as out */);
  return sk_surface_;
}

bool IOSSurfaceSoftware::PresentBackingStore(sk_sp<SkSurface> backing_store) {
  TRACE_EVENT0("flutter", "IOSSurfaceSoftware::PresentBackingStore");
  if (!IsValid() || backing_store == nullptr) {
    return false;
  }

  SkPixmap pixmap;
  if (!backing_store->peekPixels(&pixmap)) {
    return false;
  }

  // Some basic sanity checking.
  uint64_t expected_pixmap_data_size = pixmap.width() * pixmap.height() * 4;

  if (expected_pixmap_data_size != pixmap.getSize64()) {
    return false;
  }

  fml::CFRef<CGColorSpaceRef> colorspace(CGColorSpaceCreateDeviceRGB());

  // Setup the data provider that gives CG a view into the pixmap.
  fml::CFRef<CGDataProviderRef> pixmap_data_provider(CGDataProviderCreateWithData(
      nullptr,             // info
      pixmap.addr32(),     // data
      pixmap.getSize64(),  // size
      nullptr              // release callback
      ));

  if (!pixmap_data_provider) {
    return false;
  }

  // Create the CGImageRef representation on the pixmap.
  fml::CFRef<CGImageRef> pixmap_image(CGImageCreate(pixmap.width(),     // width
                                                    pixmap.height(),    // height
                                                    8,                  // bits per component
                                                    32,                 // bits per pixel
                                                    pixmap.rowBytes(),  // bytes per row
                                                    colorspace,         // colorspace
                                                    kCGImageAlphaPremultipliedLast,  // bitmap info
                                                    pixmap_data_provider,      // data provider
                                                    nullptr,                   // decode array
                                                    false,                     // should interpolate
                                                    kCGRenderingIntentDefault  // rendering intent
                                                    ));

  if (!pixmap_image) {
    return false;
  }

  CALayer* layer = GetLayer();
  layer.contents = reinterpret_cast<id>(static_cast<CGImageRef>(pixmap_image));

  return true;
}

}  // namespace shell
