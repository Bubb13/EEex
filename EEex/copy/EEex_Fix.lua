
-- BUG: v2.6.6.0 - op206/318/324 incorrectly indexes source object's items
-- list if the incoming effect's source spell has a name strref of -1
-- without first checking if the source was a sprite.
function EEex_Fix_Hook_SpellImmunityShouldSkipItemIndexing(object)
    return object.m_objectType ~= CGameObjectType.SPRITE
end
