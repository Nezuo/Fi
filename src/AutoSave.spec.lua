return function()
    local AutoSave = require(script.Parent.AutoSave)
    local Constants = require(script.Parent.Constants)
    local Fi = require(script.Parent)

    it("should add and remove profile from auto save queue", function()
        local Store = Fi:GetProfileStore("Store")
        local MyProfile = Store:LoadProfile("Profile"):await():unwrapOrDie()

        expect(Fi.AutoSaveQueue:IsEmpty()).to.equal(false)
        expect(Fi.AutoSaveQueue:Length()).to.equal(1)
        expect(Fi.AutoSaveQueue:Peek()).to.equal(MyProfile)

        Fi:ReleaseProfile(MyProfile):await()

        expect(Fi.AutoSaveQueue:IsEmpty()).to.equal(true)
        expect(Fi.AutoSaveQueue:Length()).to.equal(0)
        expect(Fi.AutoSaveQueue:Peek()).never.to.be.ok()
    end)

    it("should add and remove profiles from auto save queue", function()
        local Store = Fi:GetProfileStore("Store")
        local Profiles = {}

        -- Add profiles to the auto save queue.
        for i = 1, 5 do
            Profiles[i] = Store:LoadProfile("Profile" .. i):await():unwrapOrDie()
            
            expect(Fi.AutoSaveQueue:Length()).to.equal(i)
            expect(Fi.AutoSaveQueue:Peek()).to.equal(Profiles[1])
        end

        -- Release third profile.
        Fi:ReleaseProfile(Profiles[3])

        expect(Fi.AutoSaveQueue:Length()).to.equal(4)

        -- The first two elements should stay the same.
        for i = 1, 2 do
            expect(Fi.AutoSaveQueue.Elements[i]).to.equal(Profiles[i])
        end

        -- The last two elements should have shifted down.
        for i = 3, 4 do
            expect(Fi.AutoSaveQueue.Elements[i]).to.equal(Profiles[i + 1])
        end
    end)

    it("should auto save profile", function()
        local Store = Fi:GetProfileStore("Store")
        local MyProfile = Store:LoadProfile("Profile"):await():unwrapOrDie()

        local Clock = os.clock()

        expect(AutoSave:Update(Clock + Constants.AUTO_SAVE_INTERVAL - 1, false)).to.equal(nil)
        expect(AutoSave:Update(Clock + Constants.AUTO_SAVE_INTERVAL, true)).to.equal(MyProfile)
        expect(AutoSave:Update(Clock + Constants.AUTO_SAVE_INTERVAL + 1, false)).to.equal(nil)
    end)

    it("should auto save profiles", function()
        local Store = Fi:GetProfileStore("Store")
        local Profiles = {}

        -- Add profiles to the auto save queue.
        for i = 1, 5 do
            Profiles[i] = Store:LoadProfile("Profile" .. i):await():unwrapOrDie()
        end

        local Clock = os.clock() + Constants.AUTO_SAVE_INTERVAL -- Add the auto save interval so the profile can save.

        local AutoSaveSpeed = Constants.AUTO_SAVE_INTERVAL / 5

        expect(AutoSave:Update(Clock, true)).to.equal(Profiles[1])

        for i = 2, 5 do
            Clock += AutoSaveSpeed

            expect(AutoSave:Update(Clock - 1, false)).to.equal(nil)
            expect(AutoSave:Update(Clock, true)).to.equal(Profiles[i])
            expect(AutoSave:Update(Clock + 1, false)).to.equal(nil)
        end

        expect(AutoSave:Update(Clock + AutoSaveSpeed)).to.equal(Profiles[1])
    end)

    it("should not save fresh profile", function()
        local Store = Fi:GetProfileStore("Store")
        
        -- Add profiles to the auto save queue.
        Store:LoadProfile("Profile1"):await():unwrapOrDie()

        local MyProfile = Store:LoadProfile("Profile2"):await():unwrapOrDie()

        local Clock = os.clock() + Constants.AUTO_SAVE_INTERVAL

        AutoSave:Update(Clock, true)

        -- Reset profile loaded timestamp to simulate brand new profile.
        MyProfile.LoadedTimestamp = Clock

        expect(AutoSave:Update(Clock + Constants.AUTO_SAVE_INTERVAL / 2)).to.equal(nil)
    end)
end