return function()
    local MockDataStoreService = require(script.Parent.MockDataStoreService.MockDataStoreService)
    local ProfileStore = require(script.Parent.ProfileStore)
    local Constants = require(script.Parent.Constants)

    Constants.TIME_BEFORE_FORCE_STEAL = 0

    describe("LoadProfile", function()
        itSKIP("should return same load job", function()
            local Store = ProfileStore.new("Store")

            Store:LoadProfile("Profile")

            expect(Store:LoadProfile("Profile")).to.equal(Store:LoadProfile("Profile"))
        end)

        it("should throw with a key more than 50 characters", function()
            local Store = ProfileStore.new("Store")

            expect(function()
                Store:LoadProfile("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
            end).to.throw("Profile key cannot be more than 50 characters.")
        end)

        it("should return a new profile", function()
            local Store = ProfileStore.new("Store")

            local Profile = Store:LoadProfile("Profile"):await():unwrapOrDie("Failed to load profile.")

            expect(#Profile.Data).to.equal(0)
            expect(Profile.ActiveSession).to.equal(game.JobId)
        end)

        it("should return an existing profile", function()
            local Store = ProfileStore.new("Store")

            MockDataStoreService:GetDataStore("Store"):UpdateAsync("Profile", function()
                return { Data = "Data" }
            end)

            local Profile = Store:LoadProfile("Profile"):await():unwrapOrDie("Failed to load profile.")

            expect(Profile.Data).to.equal("Data")
            expect(Profile.ActiveSession).to.equal(game.JobId)
        end)

        it("should steal the profile", function()
            local Store = ProfileStore.new("Store")

            MockDataStoreService:GetDataStore("Store"):UpdateAsync("Profile", function()
                return { ActiveSession = "TestSession", Data = "Data" }
            end)

            local Profile = Store:LoadProfile("Profile"):await():unwrapOrDie("Failed to load profile.")

            expect(Profile.Data).to.equal("Data")
            expect(Profile.ActiveSession).to.equal(game.JobId)
        end)

        it("should throw when loading a profile twice", function()
            local Store = ProfileStore.new("Store")

            Store:LoadProfile("Profile"):await()

            expect(function()
                Store:LoadProfile("Profile")
            end).to.throw("Profile `Profile` has already been loaded in ProfileStore `Store` in this session.")
        end)
    end)
end