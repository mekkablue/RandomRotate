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
from random import random
from GlyphsApp import Glyphs
from GlyphsApp.plugins import FilterWithDialog
from Foundation import NSAffineTransform, NSPoint

@objc.python_method
def centerOfRect(rect):
	"""
	Returns the center of NSRect rect as an NSPoint.
	"""
	x = rect.origin.x + rect.size.width * 0.5
	y = rect.origin.y + rect.size.height * 0.5
	return NSPoint(x, y)


@objc.python_method
def transform(shiftX=0.0, shiftY=0.0, rotate=0.0):
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
	if not (shiftX == 0.0 and shiftY == 0.0):
		myTransform.translateXBy_yBy_(shiftX, shiftY)
	return myTransform


class RandomRotate(FilterWithDialog):

	# Definitions of IBOutlets
	dialog = objc.IBOutlet()
	maxAngleField = objc.IBOutlet()


	@objc.python_method
	def prefDomain(self, prefName):
		return f'com.mekkablue.RandomRotate.{prefName}'


	@objc.python_method
	def pref(self, prefName):
		return Glyphs.defaults[self.prefDomain(prefName)]


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
		Glyphs.registerDefault(self.prefDomain('maxAngle'), 15.0)
		if self.pref('maxAngle') == "GlyphsToolHand":  # circumvent bug in API
			self.pref('maxAngle') = 15.0

		# Set value of text field
		self.maxAngleField.setStringValue_(self.pref('maxAngle'))

		# Set focus to text field
		self.maxAngleField.becomeFirstResponder()

	# Action triggered by UI
	@objc.IBAction
	def setMaxAngle_(self, sender):
		# Store value coming in from dialog
		self.pref('maxAngle') = 15.0
		# Trigger redraw
		self.update()

	# Actual filter
	@objc.python_method
	def filter(self, layer, inEditView, customParameters):

		# Called on font export, get value from customParameters
		if 'maxAngle' in customParameters:
			maxAngle = customParameters['maxAngle']

		# Called through UI, use stored value
		elif inEditView:
			maxAngle = float(self.pref('maxAngle') or 15)

		# fallback to default
		else:
			maxAngle = 15.0

		rotationAngle = -maxAngle + 2 * maxAngle * random()
		centerPoint = centerOfRect(layer.bounds)
		rotateLayerAroundItsCenter = transform(shiftX=-centerPoint.x, shiftY=-centerPoint.y)
		rotateLayerAroundItsCenter.appendTransform_(transform(rotate=rotationAngle))
		rotateLayerAroundItsCenter.appendTransform_(transform(shiftX=centerPoint.x, shiftY=centerPoint.y))
		layer.transform_checkForSelection_doComponents_(rotateLayerAroundItsCenter, False, True)


	@objc.python_method
	def generateCustomParameter(self):
		return "%s; maxAngle: %s;" % (self.__class__.__name__, self.pref('maxAngle'))


	@objc.python_method
	def __file__(self):
		"""Please leave this method unchanged"""
		return __file__
