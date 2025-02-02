//
//  KSTokenView.swift
//  KSTokenView
//
//  Created by Khawar Shahzad on 01/01/2015.
//  Copyright (c) 2015 Khawar Shahzad. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit


@objc enum KSTokenViewStyle: Int {
   case Rounded
   case Squared
}

@objc enum KSTokenViewScrollDirection: Int {
   case Vertical
   case Horizontal
}


//MARK: - KSTokenViewDelegate
//__________________________________________________________________________________
//

@objc protocol KSTokenViewDelegate {
   
   /**
   Asks the delegate whether the token should be added
   
   - parameter tokenView: KSTokenView object
   - parameter token:     KSToken object that needs to be added
   
   - returns: Boolean
   
   */
   optional func tokenView(tokenView: KSTokenView, shouldAddToken token: KSToken) -> Bool
   optional func tokenView(tokenView: KSTokenView, willAddToken token: KSToken)
   optional func tokenView(tokenView: KSTokenView, shouldChangeAppearanceForToken token: KSToken) -> KSToken?
   optional func tokenView(tokenView: KSTokenView, didAddToken token: KSToken)
   optional func tokenView(tokenView: KSTokenView, didFailToAdd token: KSToken)
   
   optional func tokenView(tokenView: KSTokenView, shouldDeleteToken token: KSToken) -> Bool
   optional func tokenView(tokenView: KSTokenView, willDeleteToken token: KSToken)
   optional func tokenView(tokenView: KSTokenView, didDeleteToken token: KSToken)
   optional func tokenView(tokenView: KSTokenView, didFailToDeleteToken token: KSToken)
   
   optional func tokenView(tokenView: KSTokenView, willChangeFrame frame: CGRect)
   optional func tokenView(tokenView: KSTokenView, didChangeFrame frame: CGRect)
   
   optional func tokenView(tokenView: KSTokenView, didSelectToken token: KSToken)
   optional func tokenViewDidBeginEditing(tokenView: KSTokenView)
   optional func tokenViewDidEndEditing(tokenView: KSTokenView)
   
   func tokenView(token: KSTokenView, performSearchWithString string: String, completion: ((results: Array<AnyObject>) -> Void)?)
   func tokenView(token: KSTokenView, displayTitleForObject object: AnyObject) -> String
   optional func tokenView(token: KSTokenView, withObject object: AnyObject, tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   optional func tokenView(token: KSTokenView, didSelectRowAtIndexPath indexPath: NSIndexPath)
   
   optional func tokenViewShouldDeleteAllToken(tokenView: KSTokenView) -> Bool
   optional func tokenViewWillDeleteAllToken(tokenView: KSTokenView)
   optional func tokenViewDidDeleteAllToken(tokenView: KSTokenView)
   optional func tokenViewDidFailToDeleteAllTokens(tokenView: KSTokenView)
   
   optional func tokenViewDidShowSearchResults(tokenView: KSTokenView)
   optional func tokenViewDidHideSearchResults(tokenView: KSTokenView)
}

//MARK: - KSTokenView
//__________________________________________________________________________________
//

/**
*  A KSTokenView is a control that displays a collection of tokens in a an editable UITextField and sends messages to delegate object. It can be used to gather small amounts of text from user and perform search operation. User can choose multiple search results, which are displayed as token in UITextField.
*/
class KSTokenView: UIView {
   
   //MARK: - Private Properties
   //__________________________________________________________________________________
   //
   private var _tokenField: KSTokenField!
   private var _searchTableView: UITableView = UITableView(frame: .zeroRect, style: UITableViewStyle.Plain)
   private var _resultArray = [AnyObject]()
   private var _showingSearchResult = false
   private var _indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
   private var _popover: UIPopoverController?
   private let _searchResultHeight: CGFloat = 200.0
   private var _lastSearchString: String = ""
   
   //MARK: - Public Properties
   //__________________________________________________________________________________
   //
   
   /// default is true. token can be deleted with keyboard 'x' button
   var shouldDeleteTokenOnBackspace = true
   
   /// Only works for iPhone now, not iPad devices. default is false. If true, search results are hidden when one of them is selected
   var shouldHideSearchResultsOnSelect = false
   
   /// default is false. If true, already added token still appears in search results
   var shouldDisplayAlreadyTokenized = false
   
   /// default is ture. Sorts the search results alphabatically according to title provided by tokenView(_:displayTitleForObject) delegate
   var shouldSortResultsAlphabatically = true
   
   /// default is true. If false, token can only be added from picking search results. All the text input would be ignored
   var shouldAddTokenFromTextInput = true
   
   /// default is 1
   var minimumCharactersToSearch = 1
   
   /// default is nil
   weak var delegate: KSTokenViewDelegate?
   
   /// default is .Vertical.
   var direction: KSTokenViewScrollDirection = .Vertical {
      didSet {
         _updateTokenField()
      }
   }
   
   /// Default is whiteColor
   override var backgroundColor: UIColor? {
      didSet {
         if (oldValue != backgroundColor && _tokenField != nil) {
            _tokenField.backgroundColor = backgroundColor
         }
      }
   }
   
   /// Default is (TokenViewWidth, 200)
   var searchResultSize: CGSize = CGSize.zeroSize {
      didSet {
         if (KSUtils.isIpad()) {
            _popover?.popoverContentSize = searchResultSize
         } else {
            _searchTableView.frame.size = searchResultSize
         }
      }
   }
   
   /// Default is whiteColor()
   var searchResultBackgroundColor: UIColor = UIColor.whiteColor() {
      didSet {
         if (KSUtils.isIpad()) {
            _popover?.contentViewController.view.backgroundColor = searchResultBackgroundColor
            _popover?.backgroundColor = searchResultBackgroundColor
         } else {
            _searchTableView.backgroundColor = searchResultBackgroundColor
         }
      }
   }
   
   /// default is UIColor.blueColor()
   var activityIndicatorColor: UIColor = UIColor.blueColor() {
      didSet {
         _indicator.color = activityIndicatorColor
      }
   }
   
   /// default is 120.0. After maximum limit is reached, tokens starts scrolling vertically
   var maximumHeight: CGFloat = 120.0 {
      didSet {
         _tokenField.maximumHeight = maximumHeight
      }
   }
   
   /// default is UIColor.grayColor()
   var cursorColor: UIColor = UIColor.grayColor() {
      didSet {
         _updateTokenField()
      }
   }
   
   /// default is 10.0. Horizontal padding of title
   var paddingX: CGFloat = 10.0 {
      didSet {
         if (oldValue != paddingX) {
            _updateTokenField()
         }
      }
   }
   
   /// default is 2.0. Vertical padding of title
   var paddingY: CGFloat = 2.0 {
      didSet {
         if (oldValue != paddingY) {
            _updateTokenField()
         }
      }
   }
   
   /// default is 5.0. Horizontal margin between tokens
   var marginX: CGFloat = 5.0 {
      didSet {
         if (oldValue != marginX) {
            _updateTokenField()
         }
      }
   }
   
   /// default is 5.0. Vertical margin between tokens
   var marginY: CGFloat = 5.0 {
      didSet {
         if (oldValue != marginY) {
            _updateTokenField()
         }
      }
   }
   
   /// default is UIFont.systemFontOfSize(16)
   var font: UIFont = UIFont.systemFontOfSize(16) {
      didSet {
         if (oldValue != font) {
            _updateTokenField()
         }
      }
   }
   
   /// default is 50.0. Caret moves to new line if input width is less than this value
   var minWidthForInput: CGFloat = 50.0 {
      didSet {
         if (oldValue != minWidthForInput) {
            _updateTokenField()
         }
      }
   }
   
   /// default is ", ". Used to separate titles when untoknized
   var separatorText: String = ", " {
      didSet {
         if (oldValue != separatorText) {
            _updateTokenField()
         }
      }
   }
   
   /// An array of string values. Default values are " " and ",". Token is created when any of the character in this Array is pressed
   var tokenizingCharacters = [" ", ","]
   
   /// default is 0.25.
   var animateDuration: NSTimeInterval = 0.25 {
      didSet {
         if (oldValue != animateDuration) {
            _updateTokenField()
         }
      }
   }
   
   /// default is true. When resignFirstResponder is called tokens are removed and description is displayed.
   var removesTokensOnEndEditing: Bool = true {
      didSet {
         if (oldValue != removesTokensOnEndEditing) {
            _updateTokenField()
         }
      }
   }
   
   /// Default is "selections"
   var descriptionText: String = "selections" {
      didSet {
         if (oldValue != descriptionText) {
            _updateTokenField()
         }
      }
   }
   
   /// set -1 for unlimited.
   var maxTokenLimit: Int = -1 {
      didSet {
         if (oldValue != maxTokenLimit) {
            _updateTokenField()
         }
      }
   }
   
   /// default is "To: "
   var promptText: String = "To: " {
      didSet {
         if (oldValue != promptText) {
            _updateTokenField()
         }
      }
   }
   
   /// default is true. If false, cannot be edited
   var editable: Bool = true {
      didSet(newValue) {
         _tokenField.enabled = newValue
      }
   }
   
   /// default is nil
   var placeholder: String {
      get {
         return _tokenField.placeholder!
      }
      set {
         _tokenField.placeholder = newValue
      }
   }
   
   /// default is .Rounded, creates rounded corner
   var style: KSTokenViewStyle = .Rounded {
      didSet(newValue) {
         _updateTokenFieldLayout(style)
      }
   }
   
   //MARK: - Constructors
   //__________________________________________________________________________________
   //
   
   /**
   Create and inialize KSTokenView object
   
   - parameter frame: An object of type CGRect
   
   - returns: KSTokenView object
   */
   override init(frame: CGRect) {
      super.init(frame: frame)
      _commonSetup()
   }
   
   /**
   Create and inialize KSTokenView object from Interface builder
   
   - parameter aDecoder: An object of type NSCoder
   
   - returns: KSTokenView object
   */
   required init(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }
   
   override func awakeFromNib() {
      _commonSetup()
   }
   
   //MARK: - Common Setup
   //__________________________________________________________________________________
   //
   
   private func _commonSetup() {
      backgroundColor = UIColor.clearColor()
      _tokenField = KSTokenField(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
      _tokenField.textColor = UIColor.blackColor()
      _tokenField.enabled = true
      _tokenField.tokenFieldDelegate = self
      _tokenField.placeholder = ""
      _tokenField.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
      _updateTokenField()
      addSubview(_tokenField)
      
      _indicator.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
      _indicator.hidesWhenStopped = true
      _indicator.stopAnimating()
      _indicator.color = activityIndicatorColor
      
      searchResultSize = CGSize(width: frame.width, height: _searchResultHeight)
      _searchTableView.frame = CGRectMake(0, frame.height, searchResultSize.width, searchResultSize.height)
      _searchTableView.delegate = self
      _searchTableView.dataSource = self
      
      if KSUtils.isIpad() {
         let viewController = UIViewController()
         viewController.view = _searchTableView
         _popover = UIPopoverController(contentViewController: viewController)
         _popover?.delegate = self
         _popover?.backgroundColor = searchResultBackgroundColor
         _popover?.passthroughViews = subviews
         _popover?.popoverContentSize = searchResultSize
         
      } else {
         addSubview(_searchTableView)
         _hideSearchResults()
      }
   }
   
   //MARK: - Layout changes
   //__________________________________________________________________________________
   //
   override func layoutSubviews() {
      _tokenField.updateLayout(false)
      _searchTableView.frame.size = CGSize(width: frame.width, height: searchResultSize.height)
   }
   
   //MARK: - Private Methods
   //__________________________________________________________________________________
   //
   
   private func _updateTokenField() {
      _tokenField.parentView = self
   }
   
   private func _updateTokenFieldLayout(newValue: KSTokenViewStyle) {
      switch (newValue) {
      case .Rounded:
         _tokenField.borderStyle = .RoundedRect
         backgroundColor = UIColor.clearColor()
         
      case .Squared:
         _tokenField.borderStyle = .Bezel
         backgroundColor = _tokenField.backgroundColor
      }
   }
   
   private func _lastToken() -> KSToken? {
      if _tokenField.tokens.count == 0 {
         return nil
      }
      return _tokenField.tokens.last
   }
   
   private func _removeToken(token: KSToken, removingAll: Bool = false) {
      if token.sticky {return}
      if (!removingAll) {
         var shouldRemoveToken: Bool? = true
         
         if let shouldRemove = delegate?.tokenView?(self, shouldDeleteToken: token) {
            shouldRemoveToken = shouldRemove
         }
         if (shouldRemoveToken != true) {
            delegate?.tokenView?(self, didFailToDeleteToken: token)
            return
         }
         delegate?.tokenView?(self, willDeleteToken: token)
      }
      _tokenField.removeToken(token, removingAll: removingAll)
      if (!removingAll) {
         delegate?.tokenView?(self, didDeleteToken: token)
         startSearchWithString(_lastSearchString)
      }
   }
   
   private func _canAddMoreToken() -> Bool {
      if (maxTokenLimit != -1 && _tokenField.tokens.count >= maxTokenLimit) {
         _hideSearchResults()
         return false
      }
      return true
   }
   
   
   /**
   Returns an Array of KSToken objects
   
   - returns: Array of KSToken objects
   */
   func tokens () -> Array<KSToken>? {
      return _tokenField.tokens
   }
   
   //MARK: - Add Token
   //__________________________________________________________________________________
   //
   
   
   /**
   Creates KSToken from input text, when user press keyboard "Done" button
   
   - parameter tokenField: Field to add in
   
   - returns: Boolean if token is added
   */
   func addTokenFromUntokenizedText(tokenField: KSTokenField) -> Bool {
      if (shouldAddTokenFromTextInput && tokenField.text != nil && tokenField.text != KSTextEmpty) {
         addTokenWithTitle(tokenField.text!)
         return true
      }
      return false
   }
   
   /**
   Creates and add a new KSToken object
   
   - parameter title:       Title of token
   - parameter tokenObject: Any custom object
   
   - returns: KSToken object
   */
   func addTokenWithTitle(title: String, tokenObject: AnyObject? = nil) -> KSToken? {
      let token = KSToken(title: title, object: tokenObject)
      return addToken(token)
   }
   
   
   /**
   Creates and add a new KSToken object
   
   - parameter token: KSToken object
   
   - returns: KSToken object
   */
   func addToken(token: KSToken) -> KSToken? {
      if (!_canAddMoreToken()) {
         return nil
      }
      
      var shouldAddToken: Bool? = true
      if let shouldAdd = delegate?.tokenView?(self, shouldAddToken: token) {
         shouldAddToken = shouldAdd
      }
      
      if (shouldAddToken != true) {
         delegate?.tokenView?(self, didFailToAdd: token)
         return nil
      }
      
      delegate?.tokenView?(self, willAddToken: token)
      var addedToken: KSToken?
      if let updaetdToken = delegate?.tokenView?(self, shouldChangeAppearanceForToken: token) {
         addedToken = _tokenField.addToken(updaetdToken)
         
      } else {
         addedToken = _tokenField.addToken(token)
      }
      
      delegate?.tokenView?(self, didAddToken: addedToken!)
      return addedToken
   }
   
   
   //MARK: - Delete Token
   //__________________________________________________________________________________
   //
   
   /**
   Deletes an already added KSToken object
   
   - parameter token: KSToken object
   */
   func deleteToken(token: KSToken) {
      _removeToken(token)
   }
   
   /**
   Searches for KSToken object and deletes
   
   - parameter object: Custom object
   */
   func deleteTokenWithObject(object: AnyObject?) {
      if object == nil {return}
      for token in _tokenField.tokens {
         if (token.object!.isEqual(object)) {
            _removeToken(token)
            break
         }
      }
   }
   
   /**
   Deletes all added tokens. This doesn't delete sticky token
   */
   func deleteAllTokens() {
      if (_tokenField.tokens.count == 0) {return}
      var shouldDeleteAllTokens: Bool? = true
      
      if let shouldRemoveAll = delegate?.tokenViewShouldDeleteAllToken?(self) {
         shouldDeleteAllTokens = shouldRemoveAll
      }
      
      if (shouldDeleteAllTokens != true) {
         delegate?.tokenViewDidFailToDeleteAllTokens?(self)
         return
      }
      
      delegate?.tokenViewWillDeleteAllToken?(self)
      for token in _tokenField.tokens {_removeToken(token, removingAll: true)}
      _tokenField.updateLayout()
      delegate?.tokenViewDidDeleteAllToken?(self)
      
      if (_showingSearchResult) {
         startSearchWithString(_lastSearchString)
      }
   }
   
   /**
   Deletes last added KSToken object
   */
   func deleteLastToken() {
      let token: KSToken? = _lastToken()
      if token != nil {
         _removeToken(token!)
      }
   }
   
   /**
   Deletes selected KSToken object
   */
   func deleteSelectedToken() {
      let token: KSToken? = selectedToken()
      if (token != nil) {
         _removeToken(token!)
      }
   }
   
   /**
   Returns Selected KSToken object
   
   - returns: KSToken object
   */
   func selectedToken() -> KSToken? {
      return _tokenField.selectedToken
   }
   
   
   //MARK: - KSTokenFieldDelegates
   //__________________________________________________________________________________
   //
   func tokenFieldDidBeginEditing(tokenField: KSTokenField) {
      delegate?.tokenViewDidBeginEditing?(self)
      tokenField.tokenize()
      if (minimumCharactersToSearch == 0) {
         startSearchWithString("")
      }
   }
   
   func tokenFieldDidEndEditing(tokenField: KSTokenField) {
      delegate?.tokenViewDidEndEditing?(self)
      tokenField.untokenize()
      _hideSearchResults()
   }
   
   override func becomeFirstResponder() -> Bool {
      return _tokenField.becomeFirstResponder()
   }
   
   override func resignFirstResponder() -> Bool {
      if (!addTokenFromUntokenizedText(_tokenField)) {
         _tokenField.resignFirstResponder()
      }
      return false
   }
   
   //MARK: - Search
   //__________________________________________________________________________________
   //
   
   /**
   Triggers the search after user input text
   
   - parameter string: Search keyword
   */
   func startSearchWithString(string: String) {
      if (!_canAddMoreToken()) {
         return
      }
      _showEmptyResults()
      _showActivityIndicator()
      
      let trimmedSearchString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
      delegate?.tokenView(self, performSearchWithString:trimmedSearchString, completion: { (results) -> Void in
         self._hideActivityIndicator()
         if (results.count > 0) {
            self._displayData(results)
         }
      })
   }
   
   private func _displayData(results: Array<AnyObject>) {
      _resultArray = _filteredSearchResults(results)
      _searchTableView.reloadData()
      _showSearchResults()
   }
   
   private func _showEmptyResults() {
      _resultArray.removeAll(keepCapacity: false)
      _searchTableView.reloadData()
      _showSearchResults()
   }
   
   private func _showSearchResults() {
      if (_tokenField.isFirstResponder()) {
         _showingSearchResult = true
         if (KSUtils.isIpad()) {
            _popover?.presentPopoverFromRect(_tokenField.frame, inView: _tokenField, permittedArrowDirections: .Up, animated: false)
            
         } else {
            addSubview(_searchTableView)
            _searchTableView.frame.origin = CGPoint(x: 0, y: bounds.height)
            _searchTableView.hidden = false
         }
      }
      delegate?.tokenViewDidShowSearchResults?(self)
   }
   
   private func _hideSearchResults() {
      _showingSearchResult = false
      if (KSUtils.isIpad()) {
         _popover?.dismissPopoverAnimated(false)
         
      } else {
         _searchTableView.hidden = true
         _searchTableView.removeFromSuperview()
      }
      delegate?.tokenViewDidHideSearchResults?(self)
   }
   
   private func _repositionSearchResults() {
      if (!_showingSearchResult) {
         return
      }
      
      if (KSUtils.isIpad()) {
         if (_popover!.popoverVisible) {
            _popover?.dismissPopoverAnimated(false)
         }
         if (_showingSearchResult) {
            _popover?.presentPopoverFromRect(_tokenField.frame, inView: _tokenField, permittedArrowDirections: .Up, animated: false)
         }
         
      } else {
         _searchTableView.frame.origin = CGPoint(x: 0, y: bounds.height)
         _searchTableView.layoutIfNeeded()
      }
      
   }
   
   private func _filteredSearchResults(results: Array <AnyObject>) -> Array <AnyObject> {
      var filteredResults: Array<AnyObject> = Array()
      
      for object: AnyObject in results {
         // Check duplicates in array
         var shouldAdd = !(filteredResults as NSArray).containsObject(object)
         
         if (shouldAdd) {
            if (!shouldDisplayAlreadyTokenized && _tokenField.tokens.count > 0) {
               
               // Search if already tokenized
               for token: KSToken in _tokenField.tokens {
                  if (object.isEqual(token.object)) {
                     shouldAdd = false
                     break
                  }
               }
            }
            
            if (shouldAdd) {
               filteredResults.append(object)
            }
         }
      }
      
      if (shouldSortResultsAlphabatically) {
         return filteredResults.sort({ s1, s2 in return self._sortStringForObject(s1) < self._sortStringForObject(s2) })
      }
      return filteredResults
   }
   
   private func _sortStringForObject(object: AnyObject) -> String {
      let title = (delegate?.tokenView(self, displayTitleForObject: object))!
      return title
   }
   
   private func _showActivityIndicator() {
      _indicator.startAnimating()
      _searchTableView.tableHeaderView = _indicator
   }
   
   private func _hideActivityIndicator() {
      _indicator.stopAnimating()
      _searchTableView.tableHeaderView = nil
   }
   
   //MARK: - HitTest for _searchTableView
   //__________________________________________________________________________________
   //
   
   override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
      if (_showingSearchResult) {
         let pointForTargetView = _searchTableView.convertPoint(point, fromView: self)
         
         if (CGRectContainsPoint(_searchTableView.bounds, pointForTargetView)) {
            return _searchTableView.hitTest(pointForTargetView, withEvent: event)
         }
      }
      return super.hitTest(point, withEvent: event)
   }
   
   //MARK: - Memory Mangement
   //__________________________________________________________________________________
   //
   deinit {
      
   }
   
}

//MARK: - Extension KSTokenFieldDelegate
//__________________________________________________________________________________
//
extension KSTokenView : KSTokenFieldDelegate {
   func tokenFieldDidSelectToken(token: KSToken) {
      delegate?.tokenView?(self, didSelectToken: token)
   }
   
   func tokenFieldShouldChangeHeight(height: CGFloat) {
      delegate?.tokenView?(self, willChangeFrame: frame)
      frame.size.height = height
      
      UIView.animateWithDuration(
         animateDuration,
         animations: {
            //            self._tokenField.frame.size.height = height
            self.frame.size.height = height
            
            if (KSUtils.constrainsEnabled(self)) {
               for index in 0 ... self.constraints.count-1 {
                  let constraint: NSLayoutConstraint = self.constraints[index] as NSLayoutConstraint
                  
                  if (constraint.firstItem as! NSObject == self && constraint.firstAttribute == .Height) {
                     constraint.constant = height
                  }
               }
            }
            
            self._repositionSearchResults()
         },
         completion: {completed in
            if (completed) {
               self.delegate?.tokenView?(self, didChangeFrame: self.frame)
            }
      })
   }
}


//MARK: - Extension UITextFieldDelegate
//__________________________________________________________________________________
//
extension KSTokenView : UITextFieldDelegate {
   func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
      
      // If backspace is pressed
      if (_tokenField.tokens.count > 0 && _tokenField.text == KSTextEmpty && string.isEmpty == true && shouldDeleteTokenOnBackspace) {
         if (_lastToken() != nil) {
            if (selectedToken() != nil) {
               deleteSelectedToken()
            } else {
               _tokenField.selectToken(_lastToken()!)
            }
         }
         return false
      }
      
      // Prevent removing KSEmptyString
      if (string.isEmpty == true && _tokenField.text == KSTextEmpty) {
         return false
      }
      
      var searchString: String
      let olderText = _tokenField.text
      
      // Check if character is removed at some index
      // Remove character at that index
      if (string.isEmpty) {
         let first: String = olderText!.substringToIndex(advance(olderText!.startIndex, range.location)) as String
         let second: String = olderText!.substringFromIndex(advance(olderText!.startIndex, range.location+1)) as String
         searchString = first + second
         
      }  else { // new character added
         if (tokenizingCharacters.contains(string) && olderText != KSTextEmpty && olderText!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) != "") {
            addTokenWithTitle(olderText!, tokenObject: nil)
            return false
         }
         searchString = olderText!+string
      }
      
      // Allow all other characters
      if (searchString.characters.count >= minimumCharactersToSearch && searchString != "\n") {
         _lastSearchString = searchString
         startSearchWithString(_lastSearchString)
      }
      _tokenField.scrollViewScrollToEnd()
      return true
   }
   
   func textFieldShouldReturn(textField: UITextField) -> Bool {
      resignFirstResponder()
      return true
   }
}

//MARK: - Extension UITableViewDelegate
//__________________________________________________________________________________
//

extension KSTokenView : UITableViewDelegate {
   
   func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      delegate?.tokenView?(self, didSelectRowAtIndexPath: indexPath)
      let object: AnyObject = _resultArray[indexPath.row]
      let title  = delegate?.tokenView(self, displayTitleForObject: object)
      let token = KSToken(title: title!, object: object)
      addToken(token)
      
      if (shouldHideSearchResultsOnSelect) {
         _hideSearchResults()
         
      } else if (!shouldDisplayAlreadyTokenized) {
         _resultArray.removeAtIndex(indexPath.row)
         tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
      }
   }
}

//MARK: - Extension UITableViewDataSource
//__________________________________________________________________________________
//
extension KSTokenView : UITableViewDataSource {
   
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return _resultArray.count
   }
   
   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      
      var cell: UITableViewCell? = delegate?.tokenView?(self, withObject: _resultArray[indexPath.row], tableView: tableView, cellForRowAtIndexPath: indexPath)
      if cell != nil {
         return cell!
      }
      
      let cellIdentifier = "KSSearchTableCell"
      cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell?
      if (cell == nil) {
         cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
      }
      
      let title = delegate?.tokenView(self, displayTitleForObject: _resultArray[indexPath.row])
      cell!.textLabel!.text = (title != nil) ? title : "No Title"
      cell!.selectionStyle = UITableViewCellSelectionStyle.None
      return cell!
   }
}


//MARK: - Extension UIPopoverControllerDelegate
//__________________________________________________________________________________
//
extension KSTokenView : UIPopoverControllerDelegate {
   func popoverControllerDidDismissPopover(popoverController: UIPopoverController) {
      _showingSearchResult = false
   }
}
