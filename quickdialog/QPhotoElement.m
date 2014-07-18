//
//  QPhotoElement.m
//  QuickDialog
//
//  Created by Francis Visoiu Mistrih on 18/07/2014.
//
//

#import "QPhotoElement.h"

const float kHeightInit = 150.0; //initial height if not specified

@interface QPhotoElement () {
    UIActivityIndicatorView *loading; //activity indicator when downloading the image
}

@end

@implementation QPhotoElement

- (QPhotoElement *)init
{
    self = [super init];
    if (self) {
        _height = kHeightInit;
    }
    return self;
}

- (QPhotoElement *)initWithImage:(UIImage *)image {
    self = [self init];
    if (self) {
        _image = image;
        [[(QuickDialogController *)self.controller quickDialogTableView] reloadRowHeights];
    }
    return self;
}

- (QPhotoElement *)initWithURL:(NSString *)url {
    self = [self init];
    if (self) {
        _url = url;
        loading = [[UIActivityIndicatorView alloc] init];
        loading.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [loading startAnimating];
        [self getImageFromURL:url];
    }
    return self;
}

- (void)getImageFromURL:(NSString *)url {
    //URLWithString returns nil if the URL passed is not valid.
    NSURL *imageURL = [NSURL URLWithString:url];
    if (imageURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                _image = [UIImage imageWithData:imageData];
                if (_image) {
                    loading = nil; //force ARC to release the object
                    [[(QuickDialogController *)self.controller quickDialogTableView] reloadRowHeights];
                    [[(QuickDialogController *)self.controller quickDialogTableView] reloadCellForElements:self, nil];
                } else {
                    [self getImageFromURL:url];
                }
            });
        });
    }
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"QuickformPhoto"]];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"QuickformPhoto"];
    }

    if (!_image) {
        loading.frame = CGRectMake(0, 0, controller.view.frame.size.width, 50);
        [cell.contentView addSubview:loading];
        [self getImageFromURL:_url];
    } else {
        UIImageView *mainImage = [[UIImageView alloc] initWithImage:_image];
        mainImage.frame = CGRectMake(0, 0, controller.view.frame.size.width, _height);
        mainImage.contentMode = UIViewContentModeScaleAspectFit;
        [cell.contentView addSubview:mainImage];
    }

    return cell;
}

- (CGFloat)getRowHeightForTableView:(QuickDialogTableView *)tableView {
    _height = MIN(_height,_image.size.height);
    return loading ? 50 : _height;
}

@end
