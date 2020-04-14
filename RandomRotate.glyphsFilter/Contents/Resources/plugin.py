# encoding: utf-8
from __future__ import division, print_function, unicode_literals

###########################################################################################################
#
#
#	Filter with dialog Plugin
#
#	Read the docs:
#	https://github.com/schriftgestalt/GlyphsSDK/tree/master/Python%20Templates/Filter%20with%20Dialog
#
#	For help on the use of Interface Builder:
#	https://github.com/schriftgestalt/GlyphsSDK/tree/master/Python%20Templates
#
#
###########################################################################################################

import objc
from math import tan, radians
from random import random
from GlyphsApp import *
from GlyphsApp.plugins import *

@objc.python_method
def centerOfRect(rect):
	"""
	Returns the center of NSRect rect as an NSPoint.
	"""
	x = rect.origin.x + rect.size.width * 0.5
	y = rect.origin.y + rect.size.height * 0.5
	return NSPoint(x,y)

@objc.python_method
def transform(shiftX=0.0, shiftY=0.0, rotate=0.0, skew=0.0, scale=1.0):
	"""
	Returns an NSAffineTransform object for transforming layers.
	Apply an NSAffineTransform t object like this:
		Layer.transform_checkForSelection_doComponents_(t,False,True)
	Access its transformation matrix like this:
		tMatrix = t.transformStruct() # returns the 6-float tuple
	Apply the matrix tuple like this:
		Layer.applyTransform(tMatrix)
		Component.applyTransform(tMatrix)
		Path.applyTransform(tMatrix)
	Chain multiple NSAffineTransform objects t1, t2 like this:
		t1.appendTransform_(t2)
	"""
	myTransform = NSAffineTransform.transform()
	if rotate:
		myTransform.rotateByDegrees_(rotate)
	if scale != 1.0:
		myTransform.scaleBy_(scale)
	if not (shiftX == 0.0 and shiftY == 0.0):
		myTransform.translateXBy_yBy_(shiftX,shiftY)
	if skew:
		skewStruct = NSAffineTransformStruct()
		skewStruct.m11 = 1.0
		skewStruct.m22 = 1.0
		skewStruct.m21 = tan(radians(skew))
		skewTransform = NSAffineTransform.transform()
		skewTransform.setTransformStruct_(skewStruct)
		myTransform.appendTransform_(skewTransform)
	return myTransform


class RandomRotate(FilterWithDialog):
	
	# Definitions of IBOutlets
	dialog = objc.IBOutlet()
	maxAngleField = objc.IBOutlet()
	
	@objc.python_method
	def settings(self):
		self.menuName = Glyphs.localize({
			'en': 'Random Rotate',
			'de': 'Zufallsrotation',
			'es': 'Rotación aleatoria',
			'fr': 'Rotation aléatoire',
		})
		
		# Word on Run Button (default: Apply)
		self.actionButtonLabel = Glyphs.localize({
			'en': 'Rotate',
			'de': 'Rotieren',
			'es': 'Rotar',
			'fr': 'Tourner',
		})
		
		# Load dialog from .nib (without .extension)
		self.loadNib('IBdialog', __file__)
	
	# On dialog show
	@objc.python_method
	def start(self):
		
		# Set default value
		Glyphs.registerDefault('com.mekkablue.RandomRotate.maxAngle', 15.0)
		if Glyphs.defaults['com.mekkablue.RandomRotate.maxAngle'] == "GlyphsToolHand": # circumvent bug in API
			Glyphs.defaults['com.mekkablue.RandomRotate.maxAngle'] = 15.0
		
		# Set value of text field
		self.maxAngleField.setStringValue_(Glyphs.defaults['com.mekkablue.RandomRotate.maxAngle'])
		
		# Set focus to text field
		self.maxAngleField.becomeFirstResponder()
		
	# Action triggered by UI
	@objc.IBAction
	def setMaxAngle_( self, sender ):
		# Store value coming in from dialog
		Glyphs.defaults['com.mekkablue.RandomRotate.maxAngle'] = sender.floatValue()
		# Trigger redraw
		self.update()
	
	# Actual filter
	@objc.python_method
	def filter(self, layer, inEditView, customParameters):
		
		# Called on font export, get value from customParameters
		if 'maxAngle' in customParameters:
			maxAngle = customParameters['maxAngle']
		# Called through UI, use stored value
		else:
			maxAngle = float(Glyphs.defaults['com.mekkablue.RandomRotate.maxAngle'])
		
		rotationAngle = -maxAngle + 2*maxAngle*random()
		centerPoint = centerOfRect(layer.bounds)
		rotateLayerAroundItsCenter = transform(shiftX=-centerPoint.x, shiftY=-centerPoint.y)
		rotateLayerAroundItsCenter.appendTransform_( transform(rotate=rotationAngle) )
		rotateLayerAroundItsCenter.appendTransform_( transform(shiftX=centerPoint.x, shiftY=centerPoint.y) )
		layer.transform_checkForSelection_doComponents_( rotateLayerAroundItsCenter, False, True )
	
	@objc.python_method
	def generateCustomParameter( self ):
		return "%s; maxAngle:%s;" % (self.__class__.__name__, Glyphs.defaults['com.mekkablue.RandomRotate.maxAngle'] )
	
	@objc.python_method
	def __file__(self):
		"""Please leave this method unchanged"""
		return __file__
