--< Module >--
return {
    USE_MOCK_DATA_STORE = false; -- When set to true, Fi will use the MockDataStoreService.

    CAN_AUTO_SAVE = true; -- When set to true, Fi will automatically auto save profiles.
    AUTO_SAVE_INTERVAL = 60; -- Time in seconds between auto save for a profile. This value may vary. TODO: Add assertions to make sure this value isn't too low.

    LOAD_RETRY_DELAY = 6; -- Time between UpdateAsync attemps when loading a profile.
    TIME_BEFORE_FORCE_STEAL = 60; -- Time in seconds before it force steals a profile. TODO: Figure out how long this should be.

    ASSUME_DEAD_SESSION_LOCK = 30 * 60; -- Time in seconds until a profile's session lock is assumed to be dead.
}