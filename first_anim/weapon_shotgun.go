components {
  id: "muzzle_flash"
  component: "/first_anim/muzzle_flash.particlefx"
  position {
    x: 367.0
    y: 34.0
  }
}
components {
  id: "smoke_puff"
  component: "/first_anim/smoke_puff.particlefx"
  position {
    x: 367.0
    y: 34.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"shotgun_long\"\n"
  "material: \"/panthera/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/first_anim/weapons.atlas\"\n"
  "}\n"
  ""
}
