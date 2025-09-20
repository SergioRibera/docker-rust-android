slint::include_modules!();

fn ui() -> AppWindow {
    AppWindow::new().unwrap()
}

pub fn main() {
    ui().run().unwrap();
}

#[cfg(target_os = "android")]
#[unsafe(no_mangle)]
fn android_main(app: slint::android::AndroidApp) {
    slint::android::init(app).unwrap();
    ui().run().unwrap();
}
