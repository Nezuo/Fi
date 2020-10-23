return function()
    local Constants = require(script.Parent.Constants)

    Constants.CAN_AUTO_SAVE = false
    Constants.USE_MOCK_DATA_STORE = true

    local Fi = require(script.Parent)
    local GetDefaultData = require(script.Parent.GetDefaultData)
    local MockDataStoreConstants = require(script.Parent.MockDataStoreService.MockDataStoreConstants)
    local MockDataStoreManager = require(script.Parent.MockDataStoreService.MockDataStoreManager)
    local MockDataStoreService = require(script.Parent.MockDataStoreService)
    local Profile = require(script.Parent.Profile)
    local Queue = require(script.Parent.Queue)

    MockDataStoreConstants.BUDGETING_ENABLED = false
    MockDataStoreConstants.LOGGING_ENABLED = false
    MockDataStoreConstants.WRITE_COOLDOWN = 0
    MockDataStoreConstants.YIELD_TIME_MAX = 0

    -- TODO: Remove skips

    beforeEach(function()
        MockDataStoreManager.ResetBudget()
        MockDataStoreManager.ResetData()

        Fi.AutoSaveQueue = Queue.new()
        Fi.ProfileStores = {}
        Fi.SaveJobs = {}
        Fi.ReleaseJobs = {}
    end)

    describe("Fi", function()
        describe("GetProfileStore", function()
            it("should throw with an empty name", function()
                expect(function()
                    Fi:GetProfileStore("")
                end).to.throw("ProfileStore name cannot be an empty string.")
            end)
    
            it("should throw with a name more than 50 characters", function()
                expect(function()
                    Fi:GetProfileStore("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                end).to.throw("ProfileStore name cannot be more than 50 characters.")
            end)
    
            it("should throw when loading a store twice", function()
                expect(function()
                    Fi:GetProfileStore("Store")
                    Fi:GetProfileStore("Store")
                end).to.throw("ProfileStore `Store` has already been loaded in this session.")
            end)
    
            it("should return a ProfileStore", function()
                local Store = Fi:GetProfileStore("Store")
    
                expect(type(Store) == "table").to.be.ok()
                expect(Store.Name).to.equal("Store")
            end)
        end)
    
        describe("ReleaseProfile", function()
            it("should release profile", function()
                local Store = Fi:GetProfileStore("Store")
                local MyProfile = Profile.new(Store, "Profile", GetDefaultData("TestSession"))
                Store.Profiles[MyProfile.Key] = MyProfile -- Add to profiles because it isn't released.
    
                MockDataStoreService:GetDataStore("Store"):UpdateAsync("Profile", function()
                    return GetDefaultData(MyProfile.ActiveSession)
                end)
    
                expect(MockDataStoreService:GetDataStore("Store").__data.Profile.ActiveSession).to.equal("TestSession")
    
                Fi:ReleaseProfile(MyProfile):await()
    
                expect(MockDataStoreService:GetDataStore("Store").__data.Profile.ActiveSession).to.equal(nil)
            end)
    
            it("should throw when already released", function()
                local Store = Fi:GetProfileStore("Store")
                local MyProfile = Profile.new(Store, "Profile", GetDefaultData("TestSession"))
    
                expect(function()
                    Fi:ReleaseProfile(MyProfile)
                end).to.throw("Profile `Profile` in ProfileStore `Store` has already been released.")
            end)
    
            itSKIP("should return same release job", function()
                local Store = Fi:GetProfileStore("Store")
                local MyProfile = Profile.new(Store, "Profile", GetDefaultData("TestSession"))
                Store.Profiles[MyProfile.Key] = MyProfile -- Add to profiles because it isn't released.
    
                expect(Fi:ReleaseProfile(MyProfile)).to.equal(Fi:ReleaseProfile(MyProfile))
            end)
        end)
    
        describe("SaveProfile", function()
            it("should save profile", function()
                local Store = Fi:GetProfileStore("Store")

                local Data = GetDefaultData("TestSession")
                Data.Data = "Data"

                local MyProfile = Profile.new(Store, "Profile", Data)
    
                Fi:SaveProfile(MyProfile):await()
    
                expect(MockDataStoreService:GetDataStore("Store").__data.Profile.ActiveSession).to.equal("TestSession")
                expect(MockDataStoreService:GetDataStore("Store").__data.Profile.Data).to.equal("Data")
            end)
    
            itSKIP("should return same save job", function()
                local Store = Fi:GetProfileStore("Store")
                local MyProfile = Profile.new(Store, "Profile", GetDefaultData())
    
                expect(Fi:SaveProfile(MyProfile)).to.equal(Fi:SaveProfile(MyProfile))
            end)
        end)
    end)
end