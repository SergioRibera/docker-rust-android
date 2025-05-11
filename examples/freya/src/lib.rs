/// This is a Bevy game Example from
/// https://github.com/bevyengine/bevy/blob/main/examples/animation/animated_ui.rs
///
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use freya::prelude::*;

#[cfg(target_os = "android")]
use winit::platform::android::activity::AndroidApp;

fn add_zero(time: i64) -> String {
    if time.to_string().len() == 1 {
        let mut zero = "0".to_owned();
        zero.push_str(&time.to_string());
        zero
    } else {
        time.to_string()
    }
}

fn negative_add_zero(time: i64) -> String {
    if time < 0 {
        let number = add_zero(-time);
        let mut minus = "-".to_owned();
        minus.push_str(&number);
        minus
    } else {
        add_zero(time)
    }
}

fn format_time(time: &SystemTime, time_zone: i8) -> String {
    let current_time =
        time_zone as i64 * 3600 + time.duration_since(UNIX_EPOCH).unwrap().as_secs() as i64;
    let seconds = add_zero(current_time.rem_euclid(60));
    let minutes = add_zero(current_time.rem_euclid(3600) / 60);
    let hours = add_zero(current_time.rem_euclid(86400) / 3600);
    hours + ":" + &minutes + ":" + &seconds
}

fn app() -> Element {
    let mut system_time = use_signal(SystemTime::now);
    use_hook(move || {
        spawn(async move {
            let mut interval = tokio::time::interval(Duration::from_secs(1));

            loop {
                interval.tick().await;
                system_time.set(SystemTime::now());
            }
        });
    });

    let mut time_zone = use_signal(|| 0);
    let time = format_time(&system_time.read(), *time_zone.read());

    rsx!(
        rect {
            height: "100%",
            width: "100%",
            main_align: "center",
            cross_align: "center",
            rect {
                position: "absolute",
                Dropdown {
                    value: time_zone(),
                    ScrollView {
                        width: "200",
                        height: "300",
                        for i in -12..=14 {
                            DropdownItem {
                                value: i,
                                onpress: move |_| time_zone.set(i),
                                label { "UTC {negative_add_zero(i as i64)}:00" }
                            }
                        }
                    }
                }
            }
            rect {
                corner_radius: "16",
                padding: "12",
                background: "rgb(10, 90, 255)",
                main_align: "center",
                cross_align: "center",
                label {
                    font_family: "Consolas",
                    text_align: "center",
                    font_size: "100",
                    color: "white",
                    "{time}"
                }
            }
        }
    )
}

#[cfg(target_os = "android")]
#[no_mangle]
fn android_main(droid_app: AndroidApp) {
    use winit::platform::android::EventLoopBuilderExtAndroid;

    android_logger::init_once(
        android_logger::Config::default().with_max_level(log::LevelFilter::Debug),
    );
    log::info!("android_main started!");
    let event_loop_hook: EventLoopBuilderHook = Box::new(move |event_loop_builder| {
        event_loop_builder.with_android_app(droid_app);
    });
    launch_cfg(
        app,
        LaunchConfig::<()> {
            window_config: WindowConfig {
                size: (600.0, 600.0),
                decorations: true,
                transparent: false,
                title: "Example Freya",
                event_loop_builder_hook: Some(event_loop_hook),
                ..Default::default()
            },
            ..Default::default()
        },
    )
}

#[allow(dead_code)]
#[cfg(not(target_os = "android"))]
fn main() {
    env_logger::init();
    launch(app);
}
