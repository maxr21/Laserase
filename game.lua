local composer = require( "composer" )
local physics = require("physics")
local json = require "json"
local scene = composer.newScene()
local loadSave = require("loadsave")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local clickFinger
local mirrorGroup
local gameGroup
local beamGroup
local maxBeams=100
local obs
local bg
local back
local mirror
local destructible = {}
local emitter = {}
local maxCharge = 180
local mapW = 16
local mapH = 9
local blockW = _W/mapW
local blockH = _H/mapH
local gameState
local endMsg
local targetsInLvl
local targetsDestroyed
local isLost = false
local explosion

--mirror collision filter
local catMirror = 1
local catFloor = 2
local catOther = 4
local mirrorCollisionFilter = { categoryBits = catMirror, maskBits = catMirror + catFloor }
local floorCollisionFilter = { categoryBits = catFloor, maskBits = catMirror + catOther }
local otherCollisionFilter = { categoryBits = catOther, maskBits = catFloor + catOther}
local endMsgSh

local lvlData = {

	--level 1
	{
		winMsg = "hopefully not too difficult",
		loseMsg = "how? I don't think that's even possible",


		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,11, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{13, 0,13, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0,13,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
		}
	},
	--level 2
	{
		winMsg = "TNT bad",
		loseMsg = "Don't blow up the TNT",


		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 9, 3, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 9, 3, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 9, 3, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 2, 3, 0, 0, 0, 0, 0, 0,},
			{13, 0,11, 0, 0, 0, 9, 2, 3, 2, 0, 0, 0, 0, 0,13,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
		}
	},
	-- level 3
	{
		winMsg = "floaty castle",
		loseMsg = "unlucky",

		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]

		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 9, 9, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,11, 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{13, 0,13, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0,13,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
		}
	},
	-- level 4
	{
		winMsg = "everything is floating, and there are holes",
		loseMsg = "Falls = lose",
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 9, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 7, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 2, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{13, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 11, 0, 0, 9,13,},
			{13,13, 0, 0, 0,13,13,13,13,13,13,13,13,13,13,13,},
		},
	},

	-- level 5
	{
		winMsg = "did you like my distraction???",
		loseMsg = "Have to be quick" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 9, 9, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
			{ 0, 0, 2, 0, 2, 0, 2, 0, 7, 0, 2, 0, 2, 0, 2, 0,},
			{11, 0, 6, 0, 6, 0, 6, 0, 0, 0, 6, 0, 6, 0, 6, 0,},
			{13,13, 0,13, 0,13, 0,13,13,13, 0,13, 0,13, 0,13,},
		},
	},
	-- -- level NEW 6
	-- {
	-- 	winMsg = "did you like my distraction???",
	-- 	loseMsg = "well done" ,
	-- 	---[[
	-- 	-- objects = {
	-- 	-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
	-- 	-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
	-- 	-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
	-- 	-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
	-- 	-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
	-- 	--},
	-- 	--]]
	-- 	map = {
	-- 		{ 0, 0, 0, 0, 0, 0, 0, 0,12, 0, 9, 9, 0, 0, 0, 0,},
	-- 		{ 0, 0, 0, 7, 7, 7, 0, 0,13, 0, 0, 0, 0, 0, 0, 0,},
	-- 		{ 0, 0, 0, 8, 6, 8, 0, 0,13, 0, 6, 0, 0, 0, 0, 0,},
	-- 		{ 0, 0, 0, 7, 8, 7, 0, 0,13, 0, 0, 0, 0, 0, 0, 0,},
	-- 		{ 0, 0, 0, 0, 0, 0, 0, 0,13,13,13,13,13, 8, 7,13,},
	-- 		{ 0, 0, 0, 0, 0, 0, 0, 0,13, 6, 0, 0, 0, 0, 0, 0,},
	-- 		{ 0, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 7, 0, 0, 0,},
	-- 		{11, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 7, 0, 0,12,},
	-- 		{13, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 7, 0, 0,13,},
	-- 	},
	-- },
	-- level 6
	{
		winMsg = "completed",
		loseMsg = "i dont think you can lose this one" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 9, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0,10,10, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 2,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 8, 8, 8, 8, 8, 8, 8,13, 8, 8, 8, 8, 8, 8, 8, 8,},
			{ 0, 0, 0, 0, 0, 0, 0, 0,13,13,13,13, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 2,10, 2, 2, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0,13, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 0,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
		},
	},
	-- level 7
	{
		winMsg = "MAXIMUM MAX",
		loseMsg = "u lost" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0,10, 0, 0, 0, 0, 0, 0, 0, 0, 0,10, 9, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0,11, 0, 0, 0,13, 0, 6, 6, 6, 0,10, 0, 0, 0,10,},
			{ 0,13,13, 0,13,13, 0,13, 0,13, 0, 0, 8, 0,10, 0,},
			{ 0, 6, 0, 6, 0, 6, 0, 6, 6, 6, 0, 0, 0,10, 0, 0,},
			{ 0,13, 0, 0, 0,13, 0,13, 0,13, 0, 0,10, 0,10, 0,},
			{ 0, 6, 0,10, 0, 6, 0, 6, 0, 6, 0,10, 0, 0, 0,10,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		},
	},

	-- level 8
	{
		winMsg = "bolted mirrors are helpful",
		loseMsg = "yeah... the floor is tnt" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 9, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 6, 0, 0,10, 0, 0, 0, 0, 0, 0, 0,10,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0,10, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 6, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,11, 0, 0, 0, 0,},
			{ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,},
		},
	},
	-- level NEW 9
	{
		winMsg = "u r won",
		loseMsg = "u r losed" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 0,12, 0, 9, 9, 0, 0, 0, 0,},
			{ 0, 0, 0, 3, 7, 7, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 6, 6, 6, 0, 0, 4, 0, 6, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 7, 8, 7, 0, 0,13, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0,13,13,13,13,13, 8, 8,13,},
			{ 0, 0, 0, 0, 0, 0, 0, 0,13, 6, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 7, 0, 0, 0,},
			{11, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 7, 0, 0,12,},
			{13, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 7, 0, 0,13,},
		},
	},

	-- level 10
	{
		winMsg = "tricky?",
		loseMsg = "can u move that emitter???!??!?!?!?!?!?!?!?!??!!11/!?1/?!!?1/?!1/!" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 9, 9,10, 0, 0, 0,},
			{11, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 6, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0,13, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0,10, 0, 6,10, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 8, 0,13, 0, 2, 0, 0, 0, 0,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
		},
	},

	-- level 11
	{
		winMsg = "bolted mirrors for days",
		loseMsg = "too many bolted mirrors?" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0,},
			{ 0,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 2, 0,10,13,13,13,13,13,13,13,13,13,13,13, 6,},
			{ 0, 2, 0, 0, 6,10, 0, 0, 0, 0, 0,10, 0, 0, 0, 0,},
			{ 0, 2, 0, 0, 0, 0,10,13, 0,13, 0,13,13,13,13, 0,},
			{ 0, 2, 0, 0, 0, 0, 0, 0, 0,10, 6, 0, 0, 0, 0, 0,},
			{ 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,10,},
			{ 0,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
		},
	},

	-- level 12
	{
		winMsg = "2 emitters",
		loseMsg = "REEEE" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{11, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 9, 0, 0,},
			{ 4, 0, 0, 0, 0, 0,13, 0,13, 0, 0, 0, 0, 0, 0, 0,},
			{ 4, 0, 0, 0,13, 0, 6, 0, 6, 0, 0, 0, 0, 0, 0,10,},
			{ 4, 0,13, 0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,},
			{13,13,13,13,13,13,13,10,13,13,13,13,13,13, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,10, 0,},
			{13, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,11, 0,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
		},
	},
	-- level NEW 13
	{
		winMsg = "isn't that cool",
		loseMsg = "ran out of time?" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 9, 9, 0, 6, 0, 0,},
			{ 0, 0, 0,13,13,13,13, 0, 0,13,13,13,13, 0, 0, 0,},
			{ 0, 0,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,12, 0, 0,},
			{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,13, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0,11, 0, 0, 8, 8, 7, 7, 7, 7, 8, 8, 0, 0,12, 0,},
			{ 0,13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,10, 0,13, 0,},
		},
	},
	-- level NEW 14
	{
		winMsg = "Hope it wasn't too easy",
		loseMsg = "Maybe an emitter is causing more harm than good???" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{11, 0, 0, 0, 0, 0,10, 0,13, 0, 9, 9, 0, 0, 0, 0,},
			{13, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 0, 0, 6, 0,},
			{ 6, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 0, 0, 0, 0,},
			{13,13,13,13,13, 8,13,13,13,13,13,13,13,13, 8,13,},
			{ 0, 0, 0, 0, 0, 8, 0, 0,13, 0, 0, 0, 0, 0, 0, 0,},
			{ 6, 7, 0, 0, 0, 8, 0, 0,13, 0, 0, 0, 0, 0, 6, 0,},
			{ 6, 7, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0,12, 0, 0,},
			{ 7, 7, 0, 0, 0, 7, 0, 0,13, 0, 0, 0, 0, 8, 0, 0,},
		},
	},

	-- level 15
	{
		winMsg = "yay u won.",
		loseMsg = "wall'o'tnt" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0, 0, 0,13, 0, 3, 0, 0, 0, 0, 0, 9, 0, 0,},
			{ 0, 0, 0, 0, 0,13, 6, 3, 0, 0, 0, 0, 0, 0, 0, 0,},
			{11, 0, 0, 0, 0, 4, 0, 3, 6, 0, 0, 0, 0, 0, 0, 0,},
			{ 8, 0, 0, 0, 0, 4, 6, 3, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0,13,10, 3, 6, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0,13, 6, 3, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0,13, 0, 7, 8, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 4, 6, 4, 0, 0, 0, 0, 0,10, 0, 0,},
			{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
		},
	},

	-- level 16
	{
		winMsg = "underground digging",
		loseMsg = "darn it" ,
		---[[
		-- objects = {
		-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
		-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
		-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
		-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
		--},
		--]]
		map = {
			{ 0, 0, 0,10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,10, 9,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 2, 0, 0, 7, 0, 0, 0, 0, 0, 0, 2, 0, 0,},
			{ 0, 0, 6, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0,10,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0,10, 0, 7, 6, 7,11, 0, 0, 0, 0, 0, 0, 0,},
			{ 0, 0, 0, 0, 0, 0, 8, 8,13, 8, 8, 0, 0, 0, 0, 0,},
			{ 0, 0,13, 0, 0, 0,10, 8, 8,10, 8,13, 0, 0,13, 0,},
		},
	},


		-- level 17
		{
			winMsg = "Claw                         ",
			loseMsg = "NOOOO!" ,
			---[[
			-- objects = {
			-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
			-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
			-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
			--},
			--]]
			map = {
				{ 0, 0, 0, 0, 0, 0,13,13, 0, 0, 0, 0, 0, 9, 9, 0,},
				{ 0, 0, 0,10, 0,10,10, 0,10, 0, 0, 0, 0, 0, 0, 0,},
				{ 0, 0, 0, 6, 0, 8, 0, 8, 0, 8, 0, 0, 0, 0, 0, 0,},
				{ 0, 0, 0, 0, 7, 6, 8, 6, 8, 6, 7, 0, 0, 0, 0, 0,},
				{ 0, 0, 0, 0, 7, 7, 7, 8, 7, 7, 7, 0, 0, 0, 0, 0,},
				{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
				{ 0, 0, 0,10, 0, 0, 0,10, 0, 0, 0, 0, 0, 0, 0, 0,},
				{ 0, 0, 0, 0, 0, 0, 0,11, 0, 0, 0, 0, 0, 0, 0, 0,},
				{ 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 0, 0, 0, 0,10,},
			},
		},

		-- level NEW 18
		{
			winMsg = "another win",
			loseMsg = "Zigs zags" ,
			---[[
			-- objects = {
			-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
			-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
			-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
			--},
			--]]
			map = {
				{13, 0, 0, 0, 0, 0, 0, 6, 8, 6, 9, 9, 0, 0, 0, 0,},
				{ 0,13, 0, 0, 6, 0, 0,13, 0,13, 0, 0, 6, 0, 0,13,},
				{ 0, 0,13, 0, 0, 0,13, 0, 0, 0,13, 0, 0, 0,13, 0,},
				{ 0, 0, 0,13, 0,13, 0, 7, 7, 7, 0,13, 0,13, 0, 0,},
				{11, 0, 0, 0, 0,10, 0, 6,10, 6, 0,10, 0, 0, 0,12,},
				{13, 6, 0,13, 0,13, 0, 7, 6, 7, 0,13, 0,13, 6,13,},
				{ 0, 0,13, 0, 0, 0,13, 7, 0, 7,13, 0, 0, 0,13, 0,},
				{ 0,13, 0, 0, 0, 0, 0, 8, 0,13, 0, 0, 0, 0, 0,13,},
				{13, 0, 0, 0, 0, 0, 0, 0,13, 0, 0, 0, 0, 0, 0, 0,},
			},
		},

		-- level NEW 19
		{
			winMsg = "Split",
			loseMsg = "u lost" ,
			---[[
			-- objects = {
			-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
			-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
			-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
			--},
			--]]
			map = {
				{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 9, 9, 9, 0, 0,},
				{ 0, 0,11, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0,},
				{ 0, 0,13, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0,},
				{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 0, 0, 0, 0,},
				{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,},
				{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
				{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
				{ 0, 0, 7, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0,12, 0,},
				{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,13, 6,},
			},
		},
		-- level 20
		{
			winMsg = "whaaaaa?????",
			loseMsg = "what is this. someone help me pls" ,
			---[[
			-- objects = {
			-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
			-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
			-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
			--},
			--]]
			map = {
				{ 0, 0, 8, 8, 0, 0, 0, 7, 0, 0,10, 0, 8, 9, 8,10,},
				{ 0, 8, 0, 0,10, 0, 8, 8, 8, 0, 8, 0,10, 7, 0, 0,},
				{10, 8, 8, 0, 0, 8, 8, 8, 8, 0, 8, 0, 0, 0,10, 6,},
				{ 0,11, 0,10, 0, 8, 0, 7, 7, 8, 8, 8, 8, 8, 8, 8,},
				{ 0, 8, 8, 0, 0, 0, 0, 7, 7, 8, 8, 8, 8, 8, 8, 8,},
				{ 0, 0, 8, 8, 0, 0, 8, 8, 8, 8, 8, 8, 8, 0,10, 7,},
				{ 0, 8, 8, 0, 0, 0,10, 8, 8, 8, 8, 8, 0, 0, 0, 6,},
				{ 0, 0, 8, 0,10, 0,10, 8, 8, 8, 8, 0,10, 0, 0, 7,},
				{ 6, 8,10, 0, 0, 0, 0, 8, 8, 8, 8,10, 0, 8, 0, 0,},
			},
		},

		-- level NEW 21
		{
			winMsg = "Last level! You won the game",
			loseMsg = "get the order of destruction right the nu win." ,
			---[[
			-- objects = {
			-- 	{type = 'emitter', x = 0.3*_W, y = 0.5*_H, rot = 90,},
			-- 	--{type = 'noReflect', x = 0.3*_W, y = 0.3*_H, w = 0.05*_W, h = 0.05*_W, rot = 8,},
			-- 	{type = 'mirror', x = _W, y = 0.5*_H , w = 0.1*_W, h = _H, rot = 67,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.3*_H,},
			-- 	{type = "receiver", x = 0.7*_W, y = 0.7*_H,},
			--},
			--]]
			map = {
				{ 0, 0, 7, 0, 0,13, 0, 0, 0, 9, 9,13, 0, 0, 0, 0,},
				{ 0, 6, 7, 0, 0,13, 0, 0, 0, 0, 0,13, 0, 6, 0, 0,},
				{ 0, 0, 7, 0, 0,13, 0, 0, 0, 0, 0,13, 0, 7, 0, 0,},
				{13, 8, 7, 8, 8, 8, 0,12, 0,11, 0,13,13,13, 8,13,},
				{13, 8, 7, 8,13,13, 0, 8, 0, 8, 0, 8, 8,13, 8,13,},
				{ 0, 0, 0, 0, 6,13, 0, 0, 0,13, 0,13, 6, 7, 0, 0,},
				{ 0,10, 0, 0, 0,13, 0, 0, 0, 0, 0,13, 7, 0, 0, 0,},
				{ 0, 0, 0, 0, 0,13, 0, 0, 0, 0,10, 8, 0, 0,10, 0,},
				{ 0, 0, 0, 0, 0,13, 0, 0, 0, 0, 0,13, 0, 0, 0, 0,},
			},
		},
}



local function backFunc (e)
	if e.phase == "ended" then
		composer.gotoScene("lvlSelect", {effect = "zoomInOut", time = 1000,})
	end
end

-- print(lvlData[1].objects[].y)
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

local function gameOver ()
	isLost = true
	timer.performWithDelay( 1500, function() isLost = false end )
	gameState = "end"
	timer.performWithDelay(3000, function() backFunc({phase = 'ended'}) end )

	endMsgSh = display.newText( {parent = scene.view, align = "center", text = lvlData[lvl].loseMsg, x = 0.52*_W, y = 0.52*_H, width = _W*0.95, fontSize = 200, font = "PermanentMarker-Regular.ttf"} )
	endMsgSh:setFillColor(0,0,0,0.5)
	endMsgSh.xScale = 0.5
	endMsgSh.yScale = 0.5
	endMsgSh.alpha = 0

	endMsg = display.newText({parent = scene.view, align = "center", text = lvlData[lvl].loseMsg, x = 0.5*_W, y = 0.5*_H, width = _W*0.95, fontSize = 200, font = "PermanentMarker-Regular.ttf"})
	endMsg.xScale = 0.5
	endMsg.yScale = 0.5
	endMsg.alpha = 0
	transition.to( endMsgSh, {delay = 750, time = 1000, xScale = 1, yScale = 1, alpha = 1, transition = easing.inOutBounce} )
	transition.to( endMsg, {delay = 750, time = 1000, xScale = 1, yScale = 1, alpha = 1, transition = easing.inOutBounce} )


	physics.pause()
	back:removeEventListener('touch', backFunc)

end

 local function makeParticles(filename)

	local filePath = system.pathForFile( filename )
	local f = io.open( filePath, "r" )
	local fileData = f:read( "*a" )
	f:close()

	-- Decode the string
	local emitterParams = json.decode( fileData )
	--emitterParams.absolutePosition = true

	-- Create the emitter with the decoded parameters
	local emitter1 = display.newEmitter( emitterParams )

	return emitter1

 end


-- -- Center the emitter within the content area
-- emitter1.x = display.contentCenterX
-- emitter1.y = display.contentCenterY



local function clearObject( object )
	display.remove( object )
	object = nil
end

local function drawBeam( startX, startY, endX, endY )

	-- Draw a series of overlapping lines to represent the beam
	local beam1 = display.newLine( beamGroup, startX, startY, endX, endY )
	beam1.strokeWidth = 2 ; beam1:setStrokeColor( 1, 0.312, 0.157, 1 ) ; beam1.blendMode = "add" ; beam1:toBack()
	local beam2 = display.newLine( beamGroup, startX, startY, endX, endY )
	beam2.strokeWidth = 4 ; beam2:setStrokeColor( 1, 0.312, 0.157, 0.706 ) ; beam2.blendMode = "add" ; beam2:toBack()
	local beam3 = display.newLine( beamGroup, startX, startY, endX, endY )
	beam3.strokeWidth = 6 ; beam3:setStrokeColor( 1, 0.196, 0.157, 0.392 ) ; beam3.blendMode = "add" ; beam3:toBack()
end

-- local function resetGroup()
--   -- print(beamGroup.numChildren)
-- 	-- Clear all beams/bursts from display
-- 	for i = beamGroup.numChildren,1,-1 do
-- 		local child = beamGroup[i]
-- 		display.remove( child )
-- 		child = nil
-- 	end
--
-- 	-- Reset beam group alpha
-- 	beamGroup.alpha = 1
--
-- end


local function resetGroup(g)
  -- print(g.numChildren)
	-- Clear all from display
	if g ~= nil then

		for i = g.numChildren,1,-1 do
			local child = g[i]
			display.remove( child )
			child = nil
		end
		g.alpha = 1
	end
	-- Reset group alpha

end

local function bang ()
	print("bang")
	audio.play(explosion)

end



local function castRay( startX, startY, endX, endY )

	-- Perform ray cast
	local hits = physics.rayCast( startX, startY, endX, endY, "closest" )

	-- There is a hit; calculate the entire ray sequence (initial ray and reflections)
	if ( hits and beamGroup.numChildren <= maxBeams ) then

		-- Store first hit to variable (just the "closest" hit was requested, so use 'hits[1]')
		local hitFirst = hits[1]

		-- Store the hit X and Y position to local variables
		local hitX, hitY = hitFirst.position.x, hitFirst.position.y

		-- Place a visual "burst" at the hit point and animate it
		local burst = display.newImageRect( beamGroup, "burst.png", 64, 64 )
		burst.rotation = rnd(0,360)
		burst.x, burst.y = hitX, hitY
		burst.blendMode = "add"
		transition.to( burst, { time=1, onComplete=clearObject } )

			-- Draw the next beam
		drawBeam( startX, startY, hitX, hitY )
		if hitFirst.object.id == "noReflect" then

			--transition.to( beamGroup, { time=800, delay=400, alpha=0, onComplete=resetGroup } )
		elseif hitFirst.object.id == "canDest"  then

			if hitFirst.object.type == 'tnt' then
				hitFirst.object.charge = hitFirst.object.charge + 0.8
			else
				hitFirst.object.charge = hitFirst.object.charge + 1
			end

			if hitFirst.object.charge >= maxCharge then
				local emitter
				if hitFirst.object.emitter ~= nil then
					display.remove(hitFirst.object.emitter)
				end
				print("value correct")
				physics.removeBody(hitFirst.object)

				explosion = audio.loadSound( "firework_medium_distant_explosion.mp3" )
				audio.play( explosion )

				if hitFirst.object.type == "tnt" then

					print("TNT")
					timer.performWithDelay( 400, bang)
					timer.performWithDelay( 700, bang)
					timer.performWithDelay( 950, bang)
					emitter = makeParticles("particle_texture.json")
					gameOver()

				elseif hitFirst.object.type == "target" then
					print("target hit")
					emitter = makeParticles("particle_texture.json")
					targetsDestroyed = targetsDestroyed + 1
					if targetsInLvl == targetsDestroyed then
						gameState = "end"

						endMsgSh = display.newText( {parent = scene.view, align = "center", text = lvlData[lvl].winMsg, x = 0.52*_W, y = 0.52*_H, width = 0.95*_W, fontSize = 200, font = "PermanentMarker-Regular.ttf"} )
						endMsgSh:setFillColor(0,0,0,0.5)
						endMsgSh.xScale = 0.5
						endMsgSh.yScale = 0.5
						endMsg = display.newText({parent = scene.view, align = "center", text = lvlData[lvl].winMsg, x = 0.5*_W, y = 0.5*_H, width = 0.95*_W, fontSize = 200, font = "PermanentMarker-Regular.ttf"})
						endMsg.xScale = 0.5
						endMsg.yScale = 0.5
						endMsgSh.alpha = 0
						endMsg.alpha = 0
						transition.to( endMsgSh, {delay = 750, time = 1000, xScale = 1, yScale = 1, alpha = 1, transition = easing.inOutBounce} )
						transition.to( endMsg, {delay = 750, time = 1000, xScale = 1, yScale = 1, alpha = 1, transition = easing.inOutBounce} )
						local winSnd = audio.loadSound( "zapsplat_multimedia_game_star_win_gain_x1_12387.mp3")
						audio.play( winSnd )
						timer.performWithDelay( 5000, function() backFunc({phase = 'ended'}) end )
						physics.pause()
						back:removeEventListener('touch', backFunc)

						if lvl < numLvls then
							saveData.locked[lvl+1] = false
							print(lvl+1 .. "unlocked")
							loadSave.saveTable(saveData, "scores.json")
						end
					end

				else
					emitter = makeParticles("particle_texture.json")
				end

				emitter.x = hitFirst.object.x
				emitter.y = hitFirst.object.y
			end
		else
			-- Check for and calculate the reflected ray
			local reflectX, reflectY = physics.reflectRay( startX, startY, hitFirst )
			local reflectLen = 2600
			local reflectEndX = ( hitX + ( reflectX * reflectLen ) )
			local reflectEndY = ( hitY + ( reflectY * reflectLen ) )

			-- If the ray is reflected, cast another ray

			if ( reflectX and reflectY ) then
				castRay( hitX, hitY, reflectEndX, reflectEndY )
			end
		end
	-- Else, ray casting sequence is complete
	else

		-- Draw the final beam
		drawBeam( startX, startY, endX, endY )

	end
end

local function updateGame (e)
	-- Delete the beams


	resetGroup(beamGroup)
	if gameState == "playing" then
		for i = 1, #destructible do
			if destructible[i].charge > 0 and destructible[i].charge < maxCharge then
				destructible[i].charge = destructible[i].charge - 0.1
				destructible[i].alpha = 1-destructible[i].charge/maxCharge
				-- destructible[i]:setFillColor(destructible[i].charge/maxCharge,0,0)
			end
			--checking if target leaves screen
			if destructible[i] and destructible[i].type == 'target' then
				if destructible[i].x > _W or destructible[i].x < 0 or destructible[i].y > _H or destructible[i].y < 0 then
					gameOver()
				end
			end

		end

		for i =1,#emitter do
			local xDest = emitter[i].x - (math.cos(math.rad(emitter[i].rotation)) * 2600)
			local yDest = emitter[i].y - (math.sin(math.rad(emitter[i].rotation)) * 2600)
			castRay( emitter[i].x,emitter[i].y, xDest, yDest )
		end
	end
	if isLost == true then
		scene.view.x = math.random(-20,20)
	end
	-- Calculate ending x/y of beam
	-- local xDest = turret.x - (math.cos(math.rad(turret.rotation+90)) * 2600)
	-- local yDest = turret.y - (math.sin(math.rad(turret.rotation+90)) * 2600)

	-- Cast the initial ray
	-- castRay( turret.x, turret.y, xDest, yDest )

end

function moveObj (event)
	event.target.x = event.x
	event.target.y = event.y
	if event.phase == "began" then
		display.getCurrentStage():setFocus( event.target, event.id )
	elseif event.phase == "ended" then
		display.getCurrentStage():setFocus( event.target, nil)
	end
	return true
end



local function clickAnim ()

	transition.to( clickFinger, {delay = 0, time = 1000, xScale = 0.8, yScale = 0.8, alpha = 0.7, transition = easing.continuousLoop} )
	transition.to( clickFinger, {delay = 1000, time = 1000, xScale = 0.8, yScale = 0.8, alpha = 0.7, transition = easing.continuousLoop} )
	transition.to( clickFinger, {delay = 2000, time = 1000, alpha = 0} )
end

function scene:create( event )

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen



		-- bg:setFillColor(0.5,0.5,0.5)

end


-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

				if lvl <= 7 then
					bg = display.newImageRect( sceneGroup, "blurBG.png", _W, _H )
					bg.x = 0.5*_W
					bg.y = 0.5*_H
				elseif lvl <= 14 then
					bg = display.newImageRect( sceneGroup, "blurBG2.png", _W*1.1, _H*1.1 )
					bg.x = 0.5*_W
					bg.y = 0.5*_H
				elseif lvl > 14 then
					bg = display.newImageRect( sceneGroup, "blurBG3.png", _W*1, _H*1 )
					bg.x = 0.5*_W
					bg.y = 0.5*_H
				end

				back = display.newImageRect(sceneGroup, "backButton.png",0.1*_W, 0.1*_W )
				back.x = 0.1*_W
				back.y = 0.1*_H

				targetsInLvl = 0
				targetsDestroyed = 0
				gameState = "playing"

        gameGroup = display.newGroup()
        sceneGroup:insert(gameGroup)

        beamGroup = display.newGroup()
        sceneGroup:insert(beamGroup)
				mirrorGroup = display.newGroup()
				sceneGroup:insert(mirrorGroup)


        physics.start()
				--physics.setDrawMode( "hybrid" )
        physics.setGravity( 0, 9.8 )

				--[[
				for i = 1, #lvlData[lvl].objects do
					if lvlData[lvl].objects[i].type == "emitter" then
						turret = display.newImageRect( gameGroup, "turret.png", 48, 48 )
						turret.rotation = lvlData[lvl].objects[i].rot
						physics.addBody( turret, "dynamic", { radius=18 } )
						turret.x, turret.y = lvlData[lvl].objects[i].x, lvlData[lvl].objects[i].y
					elseif lvlData[lvl].objects[i].type == "noReflect" then
						obs = display.newRect(gameGroup, lvlData[lvl].objects[i].x,
						 											lvlData[lvl].objects[i].y,
																	lvlData[lvl].objects[i].w,
																	lvlData[lvl].objects[i].h)
						obs.rotation = lvlData[lvl].objects[i].rot
						physics.addBody(obs, "dynamic")
						obs.id = "noReflect"
					elseif lvlData[lvl].objects[i].type == "mirror" then
						mirror = display.newRect(gameGroup,
																						lvlData[lvl].objects[i].x,
																						lvlData[lvl].objects[i].y,
																						lvlData[lvl].objects[i].w,
																						lvlData[lvl].objects[i].h)
						mirror.rotation = lvlData[lvl].objects[i].rot
		        physics.addBody( mirror, "static" )
						mirror:addEventListener("touch", moveObj)
					elseif  lvlData[lvl].objects[i].type == "receiver" then
						local slot = #destructible + 1
						destructible[slot] = display.newRect(gameGroup, lvlData[lvl].objects[i].x, lvlData[lvl].objects[i].y, 0.05*_W, 0.05*_W)

						destructible[slot]:setFillColor(0,0,0)
						destructible[slot]:setStrokeColor(0,0,0)
						destructible[slot].strokeWidth = 4
						physics.addBody( destructible[slot], "static")
						destructible[slot].id = "canDest"
						destructible[slot].charge = 0
					else
						print("ERROR: invalid type: " .. lvlData[lvl].objects[i].type)
						native.showAlert( "ERROR", "invalid type:".. lvlData[lvl].objects[i].type, { "what?", "OMG!!!" })
					end

				end
				--]]
				if lvl == 1 then
					clickFinger = display.newImageRect(sceneGroup, "click.png",0.05*_W, 0.05*_W)
					clickFinger.x = 0.53*_W
					clickFinger.y = 0.3*_H
					clickFinger.xScale = 1.5
					clickFinger.yScale = 1.5
					timer.performWithDelay( 2000, clickAnim )

				end



				for y = 1, mapH do
					for x = 1, mapW do
						-- print(x,y)
						--print(x, y, lvlData[lvl].map[y][x])
						if lvlData[lvl].map[y][x] == 13 then
							-- print("ground")
							local ground = display.newImageRect(gameGroup, "bricks1.png", blockW*0.99, blockH*0.99)
							ground.x = ((x-0.5)*blockW)-1
							ground.y = ((y-0.5)*blockH)-1
							-- ground:setFillColor(0,1,0)
							physics.addBody(ground, "static", {friction = 0.5, bounce = 0.3, filter = floorCollisionFilter})
							ground.id = "noReflect"
						-- indestructible, gravity
						elseif lvlData[lvl].map[y][x] == 1 then
							local obstacle = display.newImageRect(gameGroup, "bricks1.png", blockW*0.99, blockH*0.99)
							obstacle.x = ((x-0.5)*blockW)
							obstacle.y = ((y-0.5)*blockH)

							obstacle.id = "noReflect"
							physics.addBody(obstacle, "dynamic", {bounce = 0.3, friction = 0.5, density = 1, filter = otherCollisionFilter})

							obstacle.isFixedRotation = true
						--destructible, gravity, should destroy
						elseif lvlData[lvl].map[y][x] == 2 then
							local slot = #destructible+1

							destructible[slot] = display.newImageRect(gameGroup, "tBricks.png", blockW*0.99, blockH*0.99)
							destructible[slot].x = (x-0.5)*blockW
							destructible[slot].y = (y-0.5)*blockH
							destructible[slot].id = "canDest"
							destructible[slot].type = "target"
							targetsInLvl = targetsInLvl + 1
							physics.addBody(destructible[slot], "dynamic", {bounce = 0.1, friction = 1, density = 1, filter = otherCollisionFilter})

							destructible[slot].charge = 0
							destructible[slot].isFixedRotation = true
						-- destructible, gravity, should not destroy
						elseif lvlData[lvl].map[y][x] == 3 then
							local slot = #destructible+1

							destructible[slot] = display.newImageRect(gameGroup,"TNT.png", blockW, blockH)
							destructible[slot].x = (x-0.5)*blockW
							destructible[slot].y = (y-0.5)*blockH
							destructible[slot].id = 'canDest'--"canDest"
							destructible[slot].type = "tnt"
							physics.addBody(destructible[slot], "dynamic", {bounce = 0.3, friction = 1, density = 1, filter = otherCollisionFilter})

							destructible[slot].charge = 0
						-- destructible, gravity, doesn't matter if destroyed

						elseif lvlData[lvl].map[y][x] == 4 then
							local slot = #destructible+1

							destructible[slot] = display.newImageRect(gameGroup,"crackBricks.png", blockW, blockH)
							destructible[slot].x = (x-0.5)*blockW
							destructible[slot].y = (y-0.5)*blockH
							destructible[slot].id = "canDest"
							physics.addBody(destructible[slot], "dynamic", {bounce = 0, friction = 1, density = 1, filter = otherCollisionFilter})

							destructible[slot].charge = 0


					-- no gravity, indestructible,
						elseif lvlData[lvl].map[y][x] == 5 then
							local obstacle3 = display.newRect(gameGroup,(x-0.5)*blockW, (y-0.5)*blockH, blockW, blockH)
							obstacle3.id = "noReflect"
							physics.addBody(obstacle3, "dynamic", {bounce = 0.3, friction = 1, filter = otherCollisionFilter})
							obstacle3.gravityScale = 0
							obstacle3:setFillColor(0,0,1)
						-- no gravity, destructible, should destroy
						elseif lvlData[lvl].map[y][x] == 6 then
							local slot = #destructible+1
							destructible[slot] = display.newImageRect(gameGroup, "tBricks.png", blockW*0.99, blockH*0.99)
							destructible[slot].x = (x-0.5)*blockW
							destructible[slot].y = (y-0.5)*blockH
							destructible[slot].id = "canDest"
							destructible[slot].type = "target"
							targetsInLvl = targetsInLvl + 1
							destructible[slot].charge = 0
							physics.addBody(destructible[slot], "static", {bounce = 0.3, friction = 0.5, filter = otherCollisionFilter})

							destructible[slot].emitter = makeParticles("particle_antigrav.json")
							gameGroup:insert(destructible[slot].emitter)
							destructible[slot].emitter.x = destructible[slot].x
							destructible[slot].emitter.y = destructible[slot].y+25

							destructible[slot].gravityScale = 0
						-- no gravity, destructible, shouldn't destroy
						elseif lvlData[lvl].map[y][x] == 7 then
							local slot = #destructible+1

							destructible[slot] = display.newImageRect(gameGroup,"tnt2.png", blockW, blockH)
							destructible[slot].x = (x-0.5)*blockW
							destructible[slot].y = (y-0.5)*blockH
							destructible[slot].id = "canDest"
							destructible[slot].type = "tnt"
							destructible[slot].charge = 0
							physics.addBody(destructible[slot], "static", {bounce = 0.3, friction = 0.5, filter = otherCollisionFilter})
							destructible[slot].emitter = makeParticles("particle_antigrav.json")
							gameGroup:insert(destructible[slot].emitter)
							destructible[slot].emitter.x = destructible[slot].x
							destructible[slot].emitter.y = destructible[slot].y+25


							destructible[slot].gravityScale = 0
						-- no gravity, destructible, doesn't matter if destroyed
						elseif lvlData[lvl].map[y][x] == 8 then
							local slot = #destructible+1
							destructible[slot] = display.newImageRect(gameGroup,"crackBricks.png", blockW, blockH)
							destructible[slot].x = (x-0.5)*blockW
							destructible[slot].y = (y-0.5)*blockH
							destructible[slot].id = "canDest"
							destructible[slot].charge = 0
							physics.addBody(destructible[slot], "static", {bounce = 0.3, friction = 0.5, filter = otherCollisionFilter})
							destructible[slot].emitter = makeParticles("particle_antigrav.json")
							gameGroup:insert(destructible[slot].emitter)
							destructible[slot].emitter.x = destructible[slot].x
							destructible[slot].emitter.y = destructible[slot].y+25

							destructible[slot].gravityScale = 0
						-- mirror, no gravity
						elseif lvlData[lvl].map[y][x] == 9 then
							local mirror1 = display.newImageRect(mirrorGroup, "Mirror.png", blockW, blockH)
							mirror1.x = (x-0.5)*blockW
							mirror1.y = (y-0.5)*blockH
							physics.addBody( mirror1, "static", {filter = mirrorCollisionFilter})
							mirror1:addEventListener("touch", moveObj)
							mirror1.rotation = 45

						--mirror, gravity
						elseif lvlData[lvl].map[y][x] == 10 then
							local mirror2 = display.newImageRect(mirrorGroup, "mirror2.png", blockW, blockH)
							physics.addBody( mirror2, "static", {filter = mirrorCollisionFilter})
							mirror2.x = (x-0.5)*blockW
							mirror2.y = (y-0.5)*blockH-2
							mirror2:setFillColor(0.7,0.7,1)
							mirror2.rotation = 45

						elseif lvlData[lvl].map[y][x] == 11 then
							print("emitter called")
							local slot = #emitter +1
							print(slot)
							emitter[slot] = display.newImageRect( mirrorGroup, "emitter.png", blockW, blockH )
							emitter[slot].x = (x-0.5)*blockW
							emitter[slot].y = (y-0.5)*blockH
							emitter[slot].rotation = 180
							physics.addBody( emitter[slot], "dynamic", {friction = 1, density = 1, bounce = 0.1, filter = otherCollisionFilter})
							emitter[slot].id = "noReflect"
							--emitterL
						elseif lvlData[lvl].map[y][x] == 12 then
							print("emitter called")
							local slot = #emitter +1
							print(slot)
							emitter[slot] = display.newImageRect( mirrorGroup, "emitter.png", blockW, blockH )
							emitter[slot].x = (x-0.5)*blockW
							emitter[slot].y = (y-0.5)*blockH
							emitter[slot].rotation = 0
							physics.addBody( emitter[slot], "dynamic", {friction = 1, density = 1, bounce = 0.1, filter = otherCollisionFilter})
							emitter[slot].id = "noReflect"


						end
					end
				end


    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        --timer.performWithDelay( 2000, fireOnTimer, 0 )


				back:addEventListener("touch", backFunc)

				Runtime:addEventListener("enterFrame", updateGame)


    end
end


-- hide()
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
			for i = 1,#destructible do
				display.remove(destructible[i])
				destructible[i] = nil
			end
			resetGroup(beamGroup)
			resetGroup(gameGroup)
			resetGroup(mirrorGroup)
			display.remove( endMsg )
			endMsg = nil

			for i = 1, #emitter do
				emitter[i] = nil
			end
			physics.stop()
			Runtime:removeEventListener("enterFrame", updateGame)
			back:removeEventListener("touch", backFunc)

    end
end


-- destroy()
function scene:destroy( event )

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
