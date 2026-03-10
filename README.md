# obsbot-camera-control-nix

OBSBOT camera control packaged for NixOS.

Automatically updated via GitHub Actions every 6 hours (tracks latest commit on main).

## Usage

### Flake

```nix
{
  inputs.obsbot-camera-control.url = "github:tomsch/obsbot-camera-control-nix";
}
```

```nix
environment.systemPackages = [ inputs.obsbot-camera-control.packages.x86_64-linux.default ];
```

### Direct build

```bash
nix build github:tomsch/obsbot-camera-control-nix
```
