--< Module >--
return {
    USE_MOCK_DATA_STORE = false; -- When set to true, Fi will use the MockDataStoreService.

    LOAD_RETRY_DELAY = 6; -- Time between UpdateAsync attemps when loading a profile.
    TIME_BEFORE_FORCE_STEAL = 60 -- Time in seconds before it force steals a profile. TODO: Figure out how long this should be.
}