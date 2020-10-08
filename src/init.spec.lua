return function()
    local Fi = require(script.Parent)

    describe("GetProfileStore", function()
        it("should return a ProfileStore", function()
            local ProfileStore = Fi:GetProfileStore("Store1")
            expect(type(ProfileStore) == "table").to.be.ok()
        end)
    end)

    describe("ProfileStore", function()
        describe("LoadProfile", function()
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
        end)
    end)
end