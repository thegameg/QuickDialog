//                                
// Copyright 2011 ESCOZ Inc  - http://escoz.com
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this 
// file except in compliance with the License. You may obtain a copy of the License at 
// 
// http://www.apache.org/licenses/LICENSE-2.0 
// 
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF 
// ANY KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import "ExampleViewController.h"
#import "QWebElement.h"
#define green_color [UIColor colorWithRed:0.373 green:0.878 blue:0.471 alpha:1]
#define blue_color [UIColor colorWithRed:0.932 green:0.976 blue:1.000 alpha:1.000]

@implementation ExampleViewController

- (QuickDialogController *)initWithRoot:(QRootElement *)rootElement {
    self = [super initWithRoot:rootElement];
    if (self) {
        for (QSection *section in rootElement.sections) {
            for (QElement *element in section.elements) {
                if ([element isKindOfClass:[QEntryElement class]]) {
                    [((QEntryElement *)element) setDelegate:self];
                }
            }
        }
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    if (!self.quickDialogTableView.editing) {
        self.quickDialogTableView.allowsSelectionDuringEditing = YES;  // required for picker element to be selectable
        [self.quickDialogTableView.controller setEditing:YES animated:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self handleBindWithJsonData:nil];
}

- (void)displayViewControllerForRoot:(QRootElement *)element {
    [element setAppearance:nil];
    QuickDialogController *newController = [self controllerForRoot: element];

    __weak ExampleViewController *weakSelf = self;
    __weak QRootElement *weakElement = element;
    newController.willDisappearCallback = ^ {
        [weakSelf changeAppearance:weakElement];
    };

    [self displayViewController:newController withPresentationMode:element.presentationMode];
}

- (void)QEntryDidEndEditingElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    [self changeAppearance:element];
}

-(void)submit:(QElement *)element {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [self.root fetchValueUsingBindingsIntoObject:dict];

    for (QSection *s in self.root.sections){
        for (QElement *el in s.elements) {
            if ([el isKindOfClass:[QRootElement class]]) {
                for (QSection *ss in ((QRootElement *)el).sections){
                    if ([ss isKindOfClass:[QSortingSection class]]) {
                        NSMutableArray *items = [[NSMutableArray alloc] init];
                        for (QSelectItemElement *selectItemEl in((QSortingSection *) ss).elements) {
                            [items addObject:selectItemEl.title];
                        }
                        [dict setObject:items forKey:el.key];
                    } else if ([ss isKindOfClass:[QSelectSection class]]) {
                        NSArray *array = ((QSelectSection *) ss).selectedIndexes ? ((QSelectSection *) ss).selectedIndexes : @[];
                        [dict setObject:array forKey:ss.key];
                    }
                }
            }
        }
    }

    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"jsonanswers"];

    NSString *msg = @"Values:";
    for (NSString *aKey in dict){
        msg = [msg stringByAppendingFormat:@"\n- %@: %@", aKey, [dict valueForKey:aKey]];
    }

    NSLog(@"%@",msg);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello"
                                                    message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(BOOL)shouldDeleteElement:(QElement *)element{

    NSIndexPath *idx = element.getIndexPath;
    [element.parentSection.elements removeObjectAtIndex:idx.row];

    // make the strong assumption that the last element is a button
    ((QButtonElement *)[element.parentSection.elements lastObject]).enabled = YES;

    [self.quickDialogTableView deleteRowsAtIndexPaths:@[idx] withRowAnimation:UITableViewRowAnimationBottom];
    [self.quickDialogTableView reloadSections:[NSIndexSet indexSetWithIndex:idx.section] withRowAnimation:UITableViewRowAnimationNone];

    // Return no if you want to delete the cell or redraw the tableView yourself
    return NO;
}

-(void)changeAppearance:(QElement *)element {
    if ([element isKindOfClass:[QEntryElement class]])
    {
        if ([((QEntryElement *)element).textValue length]) {
            QAppearance *appearance = [element.appearance copy];
            [appearance setBackgroundColorEnabled:[((QEntryElement *)element).textValue length] ? green_color : [UIColor clearColor]];
            [element setAppearance:appearance];
            [self.quickDialogTableView reloadCellForElements:element, nil];
        }
    } else if ([element isKindOfClass:[QBadgeElement class]]) {
        QAppearance *appearance = [element.appearance copy];
        [appearance setBackgroundColorEnabled:green_color];
        [element setAppearance:appearance];
        NSString *badge = @"";
        for(QSection *section in ((QRootElement *)element).sections) {
            if ([section isKindOfClass:[QSelectSection class]]) {
                badge = [NSString stringWithFormat: @"%lu", (unsigned long)[[(QSelectSection *)section selectedIndexes] count]];
            } else if ([section isKindOfClass:[QSortingSection class]]) {
                badge = [NSString stringWithFormat: @"%lu", (unsigned long)[[(QSortingSection *)section elements] count]];
            }
        }
        ((QBadgeElement *)element).badge = badge;
        [self.quickDialogTableView reloadCellForElements:element, nil];
    } else if ([element isKindOfClass:[QLabelElement class]]) {
        QAppearance *appearance = [element.appearance copy];
        [appearance setBackgroundColorEnabled:green_color];
        [element setAppearance:appearance];
        [self.quickDialogTableView cellForElement:element].accessoryType = UITableViewCellAccessoryCheckmark;
        [self.quickDialogTableView cellForElement:element].accessoryView = nil;
        [self.quickDialogTableView reloadCellForElements:element, nil];
    }
}

-(void)handleBindWithJsonData:(QElement *)button {
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"jsonanswers"];
    [self.root bindToObject:dictionary];
    [self.quickDialogTableView reloadData];
}

@end
