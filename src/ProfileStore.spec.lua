return function()
    local ProfileStore = require(script.Parent.ProfileStore)
    
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

        it("should throw when loading a profile twice", function()
            local Store = ProfileStore.new("Store")

            Store:LoadProfile("Profile"):await()

            expect(function()
                print("second time")
                Store:LoadProfile("Profile")
            end).to.throw("Profile `Profile` has already been loaded in ProfileStore `Store` in this session.")
        end)

        --[[
        it("should error", function()
            -- Should error because the profile has already been loaded
            local ProfileStore = Fi:GetProfileStore("Store2")
            
            ProfileStore:LoadProfile("Test"):map(function()
                expect(function()
                    ProfileStore:LoadProfile("Test")
                end).to.throw()
            end)
        end)
    
        it("should return a Future", function()
            local ProfileStore = Fi:GetProfileStore("Store3")
            local Future = ProfileStore:LoadProfile("Test")
            
            expect(type(Future) == "table").to.be.ok()
        end)
    
        it("should return the same Future", function()
            local ProfileStore = Fi:GetProfileStore("Store4")
            local Future = ProfileStore:LoadProfile("Test")
            local Future2 = ProfileStore:LoadProfile("Test")
            
            expect(Future).to.equal(Future2)
        end)
    
        it("should return a different Future", function()
            local ProfileStore = Fi:GetProfileStore("Store5")
            local Future = ProfileStore:LoadProfile("Test"):map(function()
                expect(Future).never.to.equal(ProfileStore:LoadProfile("Test"))
            end)
        end)
        --]]
    end)
end