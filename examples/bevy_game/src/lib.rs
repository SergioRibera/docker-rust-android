use bevy::prelude::*;

#[bevy_main]
fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_startup_system(setup)
        .add_system(update)
        .run();
}

#[derive(Component)]
struct ImageAnimated;

fn update(time: Res<Time>, mut images: Query<&mut Transform, With<ImageAnimated>>) {
    let mut transform = images.single_mut();
    transform.rotate_z(time.delta_seconds() * 5.);
}

fn setup(mut commands: Commands, asset_server: Res<AssetServer>) {
    // ui camera
    commands.spawn(Camera2dBundle::default());
    commands
        .spawn(NodeBundle {
            style: Style {
                display: Display::Flex,
                size: Size::all(Val::Percent(100.0)),
                align_items: AlignItems::Center,
                flex_direction: FlexDirection::Column,
                justify_content: JustifyContent::Center,
                gap: Size::height(Val::Px(30.)),
                ..default()
            },
            ..default()
        })
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                "Bevy Game",
                TextStyle {
                    font: asset_server.load("fonts/Lato-Regular.ttf"),
                    font_size: 60.0,
                    color: Color::rgb(0.9, 0.9, 0.9),
                },
            ));
            parent
                .spawn(ImageBundle {
                    image: UiImage::new(asset_server.load("bevy_icon.png")),
                    style: Style {
                        min_size: Size::all(Val::Px(150.)),
                        max_size: Size::all(Val::Px(150.)),
                        ..Default::default()
                    },
                    background_color: Color::WHITE.into(),
                    ..Default::default()
                })
                .insert(ImageAnimated);
        });
}
