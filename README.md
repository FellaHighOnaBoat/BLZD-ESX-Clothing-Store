# BLZD Clothing Store

A modern clothing, tattoo, outfit, and character-creation system for **FiveM ESX Legacy**.

## Features

* Full character creator
* Clothing and prop customisation
* Face and head-blend customisation
* Hair and eye colours
* Head overlays and makeup
* Clothing stores
* Tattoo stores
* Tattoo previews and body categories
* Save, load, and delete outfits
* Male and female freemode models
* Private routing bucket during character creation
* Admin clothing menu
* Automatic database setup
* `esx_skin` and `skinchanger` compatibility

## Dependencies

* `es_extended`
* `ox_lib`
* `oxmysql`

## Installation

1. Place the resource inside your resources folder:

```text
resources/[local]/BLZDClothingStore
```

2. Add the following to your `server.cfg`:

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure BLZDClothingStore
```

3. Configure the resource in `config.lua`.

4. Restart the server.

The resource automatically creates the required outfits table and adds the `appearance` column to the ESX `users` table.

## Commands

| Command          | Description                                                 |
| ---------------- | ----------------------------------------------------------- |
| `/outfits`       | Opens the saved outfits menu                                |
| `/adminclothing` | Opens the full clothing creator for authorised admin groups |
| `/debugskin`     | Prints appearance information for debugging                 |

## Configuration

### Clothing Stores

Add or remove clothing store locations using `Config.Stores`.

```lua
Config.Stores = {
    {
        coords = vector3(72.3, -1399.1, 29.4),
        radius = 20.0
    },
    {
        coords = vector3(-703.8, -152.3, 37.4),
        radius = 20.0
    },
}
```

| Option   | Description                                            |
| -------- | ------------------------------------------------------ |
| `coords` | Centre of the clothing store interaction area          |
| `radius` | Distance from the centre at which players can interact |

The included configuration contains multiple clothing store locations across the map.

### Tattoo Stores

Add or remove tattoo stores using `Config.TattooStores`.

```lua
Config.TattooStores = {
    {
        coords = vector3(322.84, 182.3, 102.59),
        radius = 5.0
    },
}
```

| Option   | Description                                            |
| -------- | ------------------------------------------------------ |
| `coords` | Centre of the tattoo store interaction area            |
| `radius` | Distance from the centre at which players can interact |

### Map Blip

```lua
Config.Blip = {
    sprite = 73,
    colour = 47,
    scale = 0.7,
    label = 'Clothing Store'
}
```

| Option   | Description           |
| -------- | --------------------- |
| `sprite` | GTA blip sprite ID    |
| `colour` | GTA blip colour ID    |
| `scale`  | Size of the blip      |
| `label`  | Name shown on the map |

A blip is created for each clothing store.

### Admin Groups

Groups allowed to use `/adminclothing` are configured here:

```lua
Config.AdminGroups = {
    'admin',
}
```

Additional groups can be added:

```lua
Config.AdminGroups = {
    'admin',
    'superadmin',
}
```

### Character Creator Locations

```lua
Config.CreatorSpawn = vector4(
    -73.97,
    -815.02,
    284.0,
    0.0
)

Config.AfterCreatorSpawn = vector4(
    327.53,
    -206.08,
    53.09,
    155.22
)
```

| Option              | Description                                                    |
| ------------------- | -------------------------------------------------------------- |
| `CreatorSpawn`      | Location where new characters are customised                   |
| `AfterCreatorSpawn` | Location where players are placed after saving their character |

New characters are placed into a private routing bucket while using the creator.

### Character Models

```lua
Config.Models = {
    male = 'mp_m_freemode_01',
    female = 'mp_f_freemode_01'
}
```

The resource is intended to use GTA Online freemode peds.

### Character Limits

```lua
Config.MaxParents = 45
Config.MaxEyeColors = 31
```

| Option         | Description                                              |
| -------------- | -------------------------------------------------------- |
| `MaxParents`   | Maximum parent ID available in the character creator     |
| `MaxEyeColors` | Maximum eye-colour ID available in the character creator |

### Face Features

Face-feature options are configured using their GTA indexes:

```lua
Config.FaceFeatures = {
    { id = 0,  label = 'Nose Width' },
    { id = 1,  label = 'Nose Peak Height' },
    { id = 2,  label = 'Nose Peak Length' },
    { id = 3,  label = 'Nose Bone Height' },
    { id = 4,  label = 'Nose Peak Lowering' },
}
```

The resource supports GTA face-feature indexes `0` through `19`.

Labels can be changed without affecting the underlying feature.

### Head Overlays

```lua
Config.HeadOverlays = {
    {
        id = 0,
        label = 'Blemishes',
        hasColor = false
    },
    {
        id = 1,
        label = 'Facial Hair',
        hasColor = true,
        colorType = 1
    },
    {
        id = 4,
        label = 'Makeup',
        hasColor = true,
        colorType = 2
    },
}
```

| Option      | Description                       |
| ----------- | --------------------------------- |
| `id`        | GTA head-overlay index            |
| `label`     | Name displayed in the menu        |
| `hasColor`  | Whether colour controls are shown |
| `colorType` | GTA overlay colour type           |

### Tattoo Zones

Tattoo categories are configured in `Config.Tattoos.zones`.

```lua
Config.Tattoos = {
    zones = {
        { id = 'head',      label = 'Head' },
        { id = 'torso',     label = 'Torso' },
        { id = 'left_arm',  label = 'L. Arm' },
        { id = 'right_arm', label = 'R. Arm' },
        { id = 'left_leg',  label = 'L. Leg' },
        { id = 'right_leg', label = 'R. Leg' },
    }
}
```

Supported zone IDs:

```text
head
torso
left_arm
right_arm
left_leg
right_leg
```

### Tattoo List

Tattoos are added to `Config.TattooList`.

```lua
Config.TattooList = {
    {
        collection = 'mpbeach_overlays',
        nameHashMale = 'MP_Bea_M_Head_000',
        nameHashFemale = '',
        displayName = 'Pirate Skull',
        zone = 'head'
    },
    {
        collection = 'mpbiker_overlays',
        nameHashMale = 'MP_MP_Biker_Tat_009_M',
        nameHashFemale = 'MP_MP_Biker_Tat_009_F',
        displayName = 'Morbid Arachnid',
        zone = 'head'
    },
}
```

| Option           | Description                            |
| ---------------- | -------------------------------------- |
| `collection`     | GTA tattoo collection name             |
| `nameHashMale`   | Overlay name used by male characters   |
| `nameHashFemale` | Overlay name used by female characters |
| `displayName`    | Tattoo name shown in the menu          |
| `zone`           | Body category containing the tattoo    |

Use an empty string when a tattoo does not have a version for one gender.

## Outfit System

Players can open the outfit menu using:

```text
/outfits
```

The outfit menu allows players to:

* Save their current appearance
* Replace an outfit by saving with the same name
* Load a saved outfit
* Delete a saved outfit

Outfit names are unique per player.

## Admin Clothing

Add the required ESX groups to:

```lua
Config.AdminGroups
```

Authorised players can then use:

```text
/adminclothing
```

This opens the full character creator without starting a new-character session.

## Database

Database migrations are run automatically when the resource starts.

The following table is created:

```sql
CREATE TABLE IF NOT EXISTS `blzd_outfits` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `clothing_data` LONGTEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_outfit` (`identifier`, `name`)
);
```

The following column is added to the ESX `users` table when it does not already exist:

```sql
ALTER TABLE `users`
ADD COLUMN `appearance` LONGTEXT DEFAULT NULL;
```

No manual SQL installation should be required.

## Exports

### Client

Get the local player's current appearance:

```lua
local appearance = exports['BLZDClothingStore']:GetSkin()
```

### Server

Get an online player's saved appearance:

```lua
local appearance =
    exports['BLZDClothingStore']:GetPlayerAppearance(source)
```

Set and apply an online player's appearance:

```lua
local success =
    exports['BLZDClothingStore']:SetPlayerAppearance(
        source,
        appearance
    )
```

Get an appearance using an ESX identifier:

```lua
local appearance =
    exports['BLZDClothingStore']:GetAppearanceByIdentifier(
        identifier
    )
```

## Notes

* The resource should remain named `BLZDClothingStore` unless internal resource references are also changed.
* The standard freemode male and female models are recommended.
* Clothing drawable IDs may differ when using custom clothing packs.
* Tattoo collection and overlay names must be valid GTA tattoo hashes.
* The current restricted-menu compatibility event opens the clothing menu but does not restrict specific components.

## Support

When reporting a problem, include:

* The error from the client or server console
* Your ESX version
* Your `ox_lib` and `oxmysql` versions
* Steps to reproduce the issue
* Any relevant changes made to the resource


This readme was  generated by AI, the code was generated by my drunken fingers. I can code, not write bollocks readmes of stuff I didn't originally intend to release.