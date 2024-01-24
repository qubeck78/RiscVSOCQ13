#include "main.h"
#include <cstring>
#include <climits>
#include <ctype.h>
#include <cstdlib>
#include <math.h>

#include "../gfxLib/bsp.h"
#include "../gfxLib/osAlloc.h"
#include "../gfxLib/osFile.h"
#include "../gfxLib/gfBitmap.h"
#include "../gfxLib/gfDrawing.h"
#include "../gfxLib/gfFont.h"
#include "../gfxLib/osUIEvents.h"
#include "../gfxLib/usbHID.h"
#include "../gfxLib/ff.h" 

extern	FATFS			fatfs;			//fs object defined in osFile.cpp
extern	tgfTextOverlay	con;

tgfBitmap 			 	screen;
tgfBitmap 			 	screen2;

char					path[256];
char 					lfnBuf[ 512 + 16];


int animLeds( int j );
int init( void );


// set to 1 to use the horizontal floor algorithm (contributed by Ádám Tóth in 2019),
// or to 0 to use the slower vertical floor algorithm.
//#define FLOOR_HORIZONTAL 1

#define screenWidth 320
#define screenHeight 200
#define texWidth 64 // must be power of two
#define texHeight 64 // must be power of two
#define mapWidth 24
#define mapHeight 24


typedef struct Sprite
{
  float x;
  float y;
  int texture;
} Sprite;


struct sortspr_t {
  float dist;
  int order;
};


#define numSprites 19


  tgfBitmap            texture[11];
  tgfBitmap            darkTexture[11];


  int worldMap[mapWidth][mapHeight] =
  {
  {8,8,8,8,8,8,8,8,8,8,8,4,4,6,4,4,6,4,6,4,4,4,6,4},
  {8,0,0,0,0,0,0,0,0,0,8,4,0,0,0,0,0,0,0,0,0,0,0,4},
  {8,0,3,3,0,0,0,0,0,8,8,4,0,0,0,0,0,0,0,0,0,0,0,6},
  {8,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6},
  {8,0,3,3,0,0,0,0,0,8,8,4,0,0,0,0,0,0,0,0,0,0,0,4},
  {8,0,0,0,0,0,0,0,0,0,8,4,0,0,0,0,0,6,6,6,0,6,4,6},
  {8,8,8,8,0,8,8,8,8,8,8,4,4,4,4,4,4,6,0,0,0,0,0,6},
  {7,7,7,7,0,7,7,7,7,0,8,0,8,0,8,0,8,4,0,4,0,6,0,6},
  {7,7,0,0,0,0,0,0,7,8,0,8,0,8,0,8,8,6,0,0,0,0,0,6},
  {7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,6,0,0,0,0,0,4},
  {7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,6,0,6,0,6,0,6},
  {7,7,0,0,0,0,0,0,7,8,0,8,0,8,0,8,8,6,4,6,0,6,6,6},
  {7,7,7,7,0,7,7,7,7,8,8,4,0,6,8,4,8,3,3,3,0,3,3,3},
  {2,2,2,2,0,2,2,2,2,4,6,4,0,0,6,0,6,3,0,0,0,0,0,3},
  {2,2,0,0,0,0,0,2,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
  {2,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
  {1,0,0,0,0,0,0,0,1,4,4,4,4,4,6,0,6,3,3,0,0,0,3,3},
  {2,0,0,0,0,0,0,0,2,2,2,1,2,2,2,6,6,0,0,5,0,5,0,5},
  {2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
  {2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5},
  {2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
  {2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
  {2,2,2,2,1,2,2,2,2,2,2,1,2,2,2,5,5,5,5,5,5,5,5,5}
  };


Sprite sprite[numSprites] =
{
  {20.5, 11.5, 10}, //green light in front of playerstart
  //green lights in every room
  {18.5,4.5, 10},
  {10.0,4.5, 10},
  {10.0,12.5,10},
  {3.5, 6.5, 10},
  {3.5, 20.5,10},
  {3.5, 14.5,10},
  {14.5,20.5,10},

  //row of pillars in front of wall: fisheye test
  {18.5, 10.5, 9},
  {18.5, 11.5, 9},
  {18.5, 12.5, 9},

  //some barrels around the map
  {21.5, 1.5, 8},
  {15.5, 1.5, 8},
  {16.0, 1.8, 8},
  {16.2, 1.2, 8},
  {3.5,  2.5, 8},
  {9.5, 15.5, 8},
  {10.0, 15.1,8},
  {10.5, 15.8,8},
};

  //1D Zbuffer
  float ZBuffer[screenWidth];

  //arrays used to sort the sprites
  int spriteOrder[numSprites];
  float spriteDistance[numSprites];

  float posX = 22.0, posY = 11.5; //x and y start position
  float dirX = -1.0, dirY = 0.0; //initial direction vector
  float planeX = 0.0, planeY = 0.66; //the 2d raycaster version of camera plane
  float pitch = 0; // looking up/down, expressed in screen pixels the horizon shifts
  float posZ = 0; // vertical camera strafing up/down, for jumping/crouching. 0 means standard height. Expressed in screen pixels a wall at distance 1 shifts


  //int __attribute__ (( cdecl )) cmpspr(const void * a, const void * b);

  //function used to sort the sprites
  void sortSprites(int* order, float * dist, int amount);

  float dmax( float  a, float  b ) { return a > b ? a : b; }
  float dmin( float  a, float  b ) { return a < b ? a : b; }

int __attribute__ (( cdecl )) cmpspr(const void * a, const void * b) {
   struct sortspr_t const* spra = (struct sortspr_t const*)a;
   struct sortspr_t const* sprb = (struct sortspr_t const*)b;
   if( spra->dist < sprb->dist ) return -1;
   else if( spra->dist > sprb->dist ) return 1;
   else return 0;
}



int animLeds( int j )
{	
		switch( j % 2 )
		{
			case 0:
				bsp->gpoPort |= 0x00f0;
				bsp->gpoPort ^= 0x0010;
			
				break;

			case 1:

				bsp->gpoPort |= 0x00f0;
				bsp->gpoPort ^= 0x0020;
			
				break;

		}
		
	return 0;
} 

int init()
{
	int rv;

	rv = 0;

	bspInit();

	setVideoMode( _VIDEOMODE_320_TEXT40_OVER_GFX );
	
	con.textAttributes = 0x0f;

	toCls( &con );


	//alloc screen buffer
	screen.width 			      = 320;
  screen.rowWidth            = 320;
	screen.height   	      = 240;
		
	screen.flags    	      = 0;
	screen.transparentColor = 0;
	screen.buffer           = osAlloc( screen.width * screen.height * 2, OS_ALLOC_MEMF_CHIP );	//osAlloc( 320 * 240 * 2 );
	
	if( screen.buffer == NULL )
	{
		toPrint( &con, ( char* )"\nCan't alloc screen\n" );
		rv = 1;
		return rv;
	} 
	
	//display screen buffer
	gfDisplayBitmap( &screen );

	//clear screen buffer
	gfFillRect( &screen, 0, 0, screen.width - 1, screen.height - 1 , gfColor( 0, 0, 0 ) ); 
	
	screen2.width 				= 320;
  screen2.rowWidth         = 320;
	screen2.height   			= 240;
		
	screen2.flags    			= 0;
	screen2.transparentColor	= 0;
	screen2.buffer           	= osAlloc( screen.width * screen.height * 2, OS_ALLOC_MEMF_CHIP );	
	
	if( screen2.buffer == NULL )
	{
		toPrint( &con, ( char* )"\nCan't alloc screen 2\n" );
		rv = 1;
		return rv;
	} 


  //clear screen buffer
  gfFillRect( &screen2, 0, 0, screen2.width - 1, screen2.height - 1 , gfColor( 0, 0, 0 ) ); 

	//init usb HID stack
	rv = usbHIDInit();
	
	if( rv )
	{
		toPrint( &con, ( char* )"USB HID init error\n" );
		
		rv = 1;
		return rv;

	}

	//init events queue
	osUIEventsInit(); 

	//init filesystem
	rv = osFInit();

	if( rv )
	{
		toPrint( &con, ( char* )"SD init error\n" );
		
		return rv;

	}

//load textures
  gfLoadBitmapFS( &texture[0], (char*)"/eagle.gbm" );
  gfLoadBitmapFS( &texture[1], (char*)"/redbrick.gbm" );
  gfLoadBitmapFS( &texture[2], (char*)"/purplestone.gbm" );
  gfLoadBitmapFS( &texture[3], (char*)"/greystone.gbm" );
  gfLoadBitmapFS( &texture[4], (char*)"/bluestone.gbm" );
  gfLoadBitmapFS( &texture[5], (char*)"/mossy.gbm" );
  gfLoadBitmapFS( &texture[6], (char*)"/wood.gbm" );
  gfLoadBitmapFS( &texture[7], (char*)"/colorstone.gbm" );

  gfLoadBitmapFS( &darkTexture[0], (char*)"/deagle.gbm" );
  gfLoadBitmapFS( &darkTexture[1], (char*)"/dredbrick.gbm" );
  gfLoadBitmapFS( &darkTexture[2], (char*)"/dpurplestone.gbm" );
  gfLoadBitmapFS( &darkTexture[3], (char*)"/dgreystone.gbm" );
  gfLoadBitmapFS( &darkTexture[4], (char*)"/dbluestone.gbm" );
  gfLoadBitmapFS( &darkTexture[5], (char*)"/dmossy.gbm" );
  gfLoadBitmapFS( &darkTexture[6], (char*)"/dwood.gbm" );
  gfLoadBitmapFS( &darkTexture[7], (char*)"/dcolorstone.gbm" );

  //load sprites
  gfLoadBitmapFS( &texture[8], (char*)"/barrel.gbm" );
  gfLoadBitmapFS( &texture[9], (char*)"/pillar.gbm" );
  gfLoadBitmapFS( &texture[10], (char*)"/greenlight.gbm" );


	return rv;
}


void raycaster( tgfBitmap *screen )
{

  int     w = 320;
  int     h = 200;

  int     x;
  int     y;


  int     lineHeight;
  int     drawStart;
  int     drawEnd;
  int     texNum;
  float   wallX;

  float  cameraX;
  float  rayDirX;
  float  rayDirY;

  int     mapX;
  int     mapY;

  //length of ray from one x or y-side to next x or y-side
  float  deltaDistX;
  float  deltaDistY;
  float  perpWallDist;

  //what direction to step in x or y-direction (either +1 or -1)
  int stepX;
  int stepY;

  int hit; //was there a wall hit?
  int side; //was a NS or a EW wall hit?

  //length of ray from current position to next x or y-side
  float   sideDistX;
  float   sideDistY;

  float   step;
  float   texPos;

  int     texX;
  int     texY;

  
  ushort  color;

#if FLOOR_HORIZONTAL
  //FLOOR CASTING
  for(int y = 0; y < screenHeight; ++y)
  {
    // whether this section is floor or ceiling
    bool is_floor = y > screenHeight / 2 + pitch;

    // rayDir for leftmost ray (x = 0) and rightmost ray (x = w)
    float rayDirX0 = (float)(dirX - planeX);
    float rayDirY0 = (float)(dirY - planeY);
    float rayDirX1 = (float)(dirX + planeX);
    float rayDirY1 = (float)(dirY + planeY);

    // Current y position compared to the center of the screen (the horizon)
    int p = (int)( is_floor ? (y - screenHeight / 2 - pitch) : (screenHeight / 2 - y + pitch) );

    // Vertical position of the camera.
    // NOTE: with 0.5, it's exactly in the center between floor and ceiling,
    // matching also how the walls are being raycasted. For different values
    // than 0.5, a separate loop must be done for ceiling and floor since
    // they're no longer symmetrical.
    float camZ = (float)( is_floor ? (0.5 * screenHeight + posZ) : (0.5 * screenHeight - posZ) );

    // Horizontal distance from the camera to the floor for the current row.
    // 0.5 is the z position exactly in the middle between floor and ceiling.
    // NOTE: this is affine texture mapping, which is not perspective correct
    // except for perfectly horizontal and vertical surfaces like the floor.
    // NOTE: this formula is explained as follows: The camera ray goes through
    // the following two points: the camera itself, which is at a certain
    // height (posZ), and a point in front of the camera (through an imagined
    // vertical plane containing the screen pixels) with horizontal distance
    // 1 from the camera, and vertical position p lower than posZ (posZ - p). When going
    // through that point, the line has vertically traveled by p units and
    // horizontally by 1 unit. To hit the floor, it instead needs to travel by
    // posZ units. It will travel the same ratio horizontally. The ratio was
    // 1 / p for going through the camera plane, so to go posZ times farther
    // to reach the floor, we get that the total horizontal distance is posZ / p.
    float rowDistance;

    if( p != 0 )
    {
      rowDistance = camZ / p;
    }
    else
    {
    rowDistance = camZ;
    }

    // calculate the real world step vector we have to add for each x (parallel to camera plane)
    // adding step by step avoids multiplications with a weight in the inner loop
    float floorStepX = rowDistance * (rayDirX1 - rayDirX0) / screenWidth;
    float floorStepY = rowDistance * (rayDirY1 - rayDirY0) / screenWidth;

    // real world coordinates of the leftmost column. This will be updated as we step to the right.
    float floorX = (float)( posX + rowDistance * rayDirX0 );
    float floorY = (float)( posY + rowDistance * rayDirY0 );

    for(int x = 0; x < screenWidth; ++x)
    {
    // the cell coord is simply got from the integer parts of floorX and floorY
    int cellX = (int)(floorX);
    int cellY = (int)(floorY);

    // get the texture coordinate from the fractional part
    int tx = (int)(texWidth * (floorX - cellX)) & (texWidth - 1);
    int ty = (int)(texHeight * (floorY - cellY)) & (texHeight - 1);

    floorX += floorStepX;
    floorY += floorStepY;

    // choose texture and draw the pixel
    int checkerBoardPattern = ((int)(cellX + cellY)) & 1;
    int floorTexture;
    if(checkerBoardPattern == 0) floorTexture = 3;
    else floorTexture = 4;
    int ceilingTexture = 6;
    ushort color;


    if(is_floor) {
      // floor
      color = ((ushort*)darkTexture[floorTexture].buffer)[texWidth * ty + tx];
      //color = (color >> 1) & 8355711; // make a bit darker

      //buffer[ x + w * y ] = (uint8_t)color;
      gfPlot( screen, x, y, color );

    } else {
      //ceiling
      color = ((ushort*)darkTexture[ceilingTexture].buffer)[texWidth * ty + tx];
      //color = (color >> 1) & 8355711; // make a bit darker
      //buffer[ x + w * y ] = (uint8_t)color;
      gfPlot( screen, x, y, color );

    }
    }
  }
#else

  gfFillRect( screen, 0, 0, w, h, 0x0 );


#endif // FLOOR_HORIZONTAL

  // WALL CASTING
  for( x = 0; x < w; x++ )
  {
    //calculate ray position and direction
    //cameraX = 2 * x / (float )(w) - 1; //x-coordinate in camera space
    cameraX = ffSub( ffDiv( 2 * x , (float )(w) ), 1.0f ); //x-coordinate in camera space

    //rayDirX = dirX + planeX * cameraX;
    rayDirX = ffAdd( dirX, ffMul( planeX, cameraX ) );
    
    //rayDirY = dirY + planeY * cameraX;
    rayDirY = ffAdd( dirY, ffMul( planeY, cameraX ) );

    //which box of the map we're in
    mapX = (int)(posX);
    mapY = (int)(posY);

    //length of ray from one x or y-side to next x or y-side
    //deltaDistX = (rayDirX == 0) ? 1e30 : fabs(1 / rayDirX);
    //deltaDistY = (rayDirY == 0) ? 1e30 : fabs(1 / rayDirY);

    deltaDistX = (rayDirX == 0) ? 1e30 : fabs( ffDiv( 1, rayDirX ) );
    deltaDistY = (rayDirY == 0) ? 1e30 : fabs( ffDiv( 1, rayDirY ) );

    hit = 0; //was there a wall hit?
    side = 0; //was a NS or a EW wall hit?

    //calculate step and initial sideDist
    if(rayDirX < 0)
    {
      stepX = -1;
      sideDistX = (posX - mapX) * deltaDistX;
    }
    else
    {
      stepX = 1;
      sideDistX = (mapX + 1.0 - posX) * deltaDistX;
    }

    if(rayDirY < 0)
    {
      stepY = -1;
      sideDistY = (posY - mapY) * deltaDistY;
    }
    else
    {
      stepY = 1;
      sideDistY = (mapY + 1.0 - posY) * deltaDistY;
    }
    
    //perform DDA
    while( hit == 0 )
    {
      
      //jump to next map square, either in x-direction, or in y-direction
      
      if( sideDistX < sideDistY )
      {
        
        //sideDistX += deltaDistX;
        //mapX += stepX;
        
        sideDistX = ffAdd( sideDistX, deltaDistX );
        mapX = ffAdd( mapX, stepX );

        side = 0;
      }
      else
      {
        //sideDistY += deltaDistY;
        //mapY += stepY;

        sideDistY = ffAdd( sideDistY, deltaDistY );
        mapY = ffAdd( mapY, stepY );

        side = 1;
      }
    
      //Check if ray has hit a wall
      
      if( worldMap[mapX][mapY] > 0 ) 
      {
        hit = 1;
      }

    }

    //Calculate distance of perpendicular ray (Euclidean distance would give fisheye effect!)
    if( side == 0 ) 
    {
      perpWallDist = (sideDistX - deltaDistX);
    }
    else        
    {
      perpWallDist = (sideDistY - deltaDistY);
    }

    //Calculate height of line to draw on screen
    lineHeight = (int)(h / perpWallDist);

    //calculate lowest and highest pixel to fill in current stripe
    drawStart = (int)( -lineHeight / 2 + h / 2 + pitch + (posZ / perpWallDist) );

    if( drawStart < 0 ) 
    {
      drawStart = 0;
    }

    drawEnd = (int)( lineHeight / 2 + h / 2 + pitch + (posZ / perpWallDist) );

    if( drawEnd >= h ) 
    {
      drawEnd = h;
    }


    //texturing calculations
    texNum = worldMap[mapX][mapY] - 1; //1 subtracted from it so that texture 0 can be used!

    //calculate value of wallX
    //where exactly the wall was hit

    if( side == 0 ) 
    {
      //wallX = posY + perpWallDist * rayDirY;
      wallX = ffAdd( posY, ffMul( perpWallDist, rayDirY ) );

    }
    else          
    {
      //wallX = posX + perpWallDist * rayDirX;
      wallX = ffAdd( posX, ffMul( perpWallDist, rayDirX ) );
    }


    wallX -= floor( wallX );

    //x coordinate on the texture
    
    texX = (int)(wallX * (float )(texWidth));
    
    if(side == 0 && rayDirX > 0) texX = texWidth - texX - 1;
    if(side == 1 && rayDirY < 0) texX = texWidth - texX - 1;

    // TODO: an integer-only bresenham or DDA like algorithm could make the texture coordinate stepping faster

    // How much to increase the texture coordinate per screen pixel
    
    //step = 1.0 * texHeight / lineHeight;
    step = ffDiv( texHeight, lineHeight );

    // Starting texture coordinate
    //texPos = (drawStart - pitch - (posZ / perpWallDist) - h / 2 + lineHeight / 2) * step;
    texPos = ffMul( (drawStart - pitch - (posZ / perpWallDist) - h / 2 + lineHeight / 2), step );
    

    for( y = drawStart; y < drawEnd; y++ )
    {
      
      // Cast the texture coordinate to integer, and mask with (texHeight - 1) in case of overflow
      texY = (int)texPos & (texHeight - 1);

      //texPos += step;
      texPos = ffAdd( texPos, step );

      if( side == 1 )
      {
        //make color darker for y-sides:
        color = ((ushort*)darkTexture[texNum].buffer)[texHeight * texY + texX];
      }
      else
      {
        color = ((ushort*)texture[texNum].buffer)[texHeight * texY + texX];
      }


      //buffer[ x + w * y ] = (uint8_t)color;
      gfPlotF( screen, x, y, color );
    }

    //SET THE ZBUFFER FOR THE SPRITE CASTING
    ZBuffer[x] = perpWallDist; //perpendicular distance is used

/*#if !FLOOR_HORIZONTAL
    //FLOOR CASTING
    float  floorXWall, floorYWall; //x, y position of the floor texel at the bottom of the wall

    //4 different wall directions possible
    if(side == 0 && rayDirX > 0)
    {
    floorXWall = mapX;
    floorYWall = mapY + wallX;
    }
    else if(side == 0 && rayDirX < 0)
    {
    floorXWall = mapX + 1.0;
    floorYWall = mapY + wallX;
    }
    else if(side == 1 && rayDirY > 0)
    {
    floorXWall = mapX + wallX;
    floorYWall = mapY;
    }
    else
    {
    floorXWall = mapX + wallX;
    floorYWall = mapY + 1.0;
    }

    float  distWall, distPlayer, currentDist;

    distWall = perpWallDist;
    distPlayer = 0.0;

    if(drawEnd < 0) drawEnd = h; //becomes < 0 when the integer overflows

    // draw the ceiling from the top of the screen to drawStart
    for(int y = 0; y < drawStart; y++)
    {
    currentDist = (h - (2.0 * posZ)) / (h - 2.0 * (y - pitch));

    float  weight = (currentDist - distPlayer) / (distWall - distPlayer);

    // Some variables here are called floor but apply to the ceiling here
    float  currentFloorX = weight * floorXWall + (1.0 - weight) * posX;
    float  currentFloorY = weight * floorYWall + (1.0 - weight) * posY;

    int floorTexX, floorTexY;
    floorTexX = (int)(currentFloorX * texWidth) & (texWidth - 1);
    floorTexY = (int)(currentFloorY * texHeight) & (texHeight - 1);


    gfPlot( screen, x, y, ((ushort*)darkTexture[6].buffer)[texWidth * floorTexY + floorTexX] );
    //buffer[ x + w * y ] = darktexture[6][texWidth * floorTexY + floorTexX];


    }

    //draw the floor from drawEnd to the bottom of the screen
    for(int y = drawEnd + 1; y < h; y++)
    {
    currentDist = (h + (2.0 * posZ)) / (2.0 * (y - pitch) - h);

    float  weight = (currentDist - distPlayer) / (distWall - distPlayer);

    float  currentFloorX = weight * floorXWall + (1.0 - weight) * posX;
    float  currentFloorY = weight * floorYWall + (1.0 - weight) * posY;

    int floorTexX, floorTexY;
    floorTexX = (int)(currentFloorX * texWidth) & (texWidth - 1);
    floorTexY = (int)(currentFloorY * texHeight) & (texHeight - 1);

    int checkerBoardPattern = ((int)currentFloorX + (int)currentFloorY) & 1;
    int floorTexture;
    if(checkerBoardPattern == 0) floorTexture = 3;
    else floorTexture = 4;

    gfPlot( screen, x, y, (((ushort*)darkTexture[floorTexture].buffer)[texWidth * floorTexY + floorTexX] >> 1 )  & 8355711 );
    //buffer[ x + w * y ] = (darktexture[floorTexture][texWidth * floorTexY + floorTexX] >> 1) & 8355711;



    }
#endif // !FLOOR_HORIZONTAL
*/
  }

    //SPRITE CASTING
  //sort sprites from far to close
    for(int i = 0; i < numSprites; i++)
    {
      spriteOrder[i] = i;
      spriteDistance[i] = ((posX - sprite[i].x) * (posX - sprite[i].x) + (posY - sprite[i].y) * (posY - sprite[i].y)); //sqrt not taken, unneeded
    }
    sortSprites(spriteOrder, spriteDistance, numSprites);

    //after sorting the sprites, do the projection and draw them
    for(int i = 0; i < numSprites; i++)
    {
      //translate sprite position to relative to camera
    float spriteX = sprite[spriteOrder[i]].x - posX;
    float spriteY = sprite[spriteOrder[i]].y - posY;

    //transform sprite with the inverse camera matrix
    // [ planeX   dirX ] -1                                       [ dirY      -dirX ]
    // [               ]       =  1/(planeX*dirY-dirX*planeY) *   [                 ]
    // [ planeY   dirY ]                                          [ -planeY  planeX ]

    float invDet = 1.0 / (planeX * dirY - dirX * planeY); //required for correct matrix multiplication

    float transformX = invDet * (dirY * spriteX - dirX * spriteY);
    float transformY = invDet * (-planeY * spriteX + planeX * spriteY); //this is actually the depth inside the screen, that what Z is in 3D, the distance of sprite to player, matching sqrt(spriteDistance[i])

      int spriteScreenX = (int)((w / 2) * (1 + transformX / transformY));

      //parameters for scaling and moving the sprites
      #define uDiv 1
      #define vDiv 1
      #define vMove 0.0
    int vMoveScreen = (int)( (int)(vMove / transformY) + pitch + posZ / transformY );

      //calculate height of the sprite on screen
      int spriteHeight = abs((int)(h / (transformY))) / vDiv; //using "transformY" instead of the real distance prevents fisheye
      //calculate lowest and highest pixel to fill in current stripe
    int drawStartY = -spriteHeight / 2 + h / 2 + vMoveScreen;
      if(drawStartY < 0) drawStartY = 0;
      int drawEndY = spriteHeight / 2 + h / 2 + vMoveScreen;
      if(drawEndY >= h) drawEndY = h - 1;

    //calculate width of the sprite
    int spriteWidth = abs( (int)(h / (transformY))) / uDiv;
    int drawStartX = -spriteWidth / 2 + spriteScreenX;
    if(drawStartX < 0) drawStartX = 0;
    int drawEndX = spriteWidth / 2 + spriteScreenX;
    if(drawEndX >= w) drawEndX = w - 1;

    //loop through every vertical stripe of the sprite on screen
    for(int stripe = drawStartX; stripe < drawEndX; stripe++)
    {
    int texX = (int)(256 * (stripe - (-spriteWidth / 2 + spriteScreenX)) * texWidth / spriteWidth) / 256;
    //the conditions in the if are:
    //1) it's in front of camera plane so you don't see things behind you
    //2) it's on the screen (left)
    //3) it's on the screen (right)
    //4) ZBuffer, with perpendicular distance
    if(transformY > 0 && stripe > 0 && stripe < w && transformY < ZBuffer[stripe])
    for(int y = drawStartY; y < drawEndY; y++) //for every pixel of the current stripe
    {
      int d = (y-vMoveScreen) * 256 - h * 128 + spriteHeight * 128; //256 and 128 factors to avoid floats
      int texY = ((d * texHeight) / spriteHeight) / 256;
      ushort color = ((ushort*)texture[sprite[spriteOrder[i]].texture].buffer)[texWidth * texY + texX]; //get current color from the texture
      if((color & 0x00FFFFFF) != 0)
      {
      gfPlot( screen, stripe, y, color );

      //buffer[ stripe + w * y ] = (uint8_t)color; //paint pixel if it isn't black, black is the invisible color
      }
    }
    }
  }

}

//sort the sprites based on distance
void sortSprites(int* order, float * dist, int amount)
{
  struct sortspr_t sprites[ 256 ];
  for(int i = 0; i < amount; i++) {
  sprites[i].dist = dist[i];
  sprites[i].order = order[i];
  }
  qsort( sprites, amount, sizeof( *sprites ), cmpspr );
  // restore in reverse order to go from farthest to nearest
  for(int i = 0; i < amount; i++) {
  dist[i] = sprites[amount - i - 1].dist;
  order[i] = sprites[amount - i - 1].order;
  }
}



int main()
{

  ulong step;

	int 			i;
	int 			rv;
//timing for input and FPS counter
  float frameTime = 4 / 60.0; //frametime is the time this frame has taken, in seconds

  //speed modifiers
  float moveSpeed = frameTime * 3.0; //the constant value is in squares/order
  float rotSpeed = frameTime * 2.0; //the constant value is in radians/order
float oldDirX;
float oldPlaneX;

	tosUIEvent		event;

	volatile int 	j;


	posX = 22.0; posY = 11.5; //x and y start position
  	dirX = -1.0; dirY = 0.0; //initial direction vector
  	planeX = 0.0; planeY = 0.66; //the 2d raycaster version of camera plane
  	pitch = 0; // looking up/down, expressed in screen pixels the horizon shifts
  	posZ = 0; // vertical camera strafing up/down, for jumping/crouching. 0 means standard height. Expressed in screen pixels a wall at distance 1 shifts

		
	rv = init();

  step = 0;
	do
	{


    if( step & 1 )
    {

      gfDisplayBitmap( &screen2 );

      do{}while( ! bsp->videoVSync );

      raycaster( &screen );

    }
    else
    {

      gfDisplayBitmap( &screen );

      do{}while( ! bsp->videoVSync );

      raycaster( &screen2 );

    }

    step++;




		usbHIDHandleEvents();
		
		if( !osGetUIEvent( &event ) )
		{

			if( event.type == OS_EVENT_TYPE_KEYBOARD_KEYPRESS )
			{
				switch( event.arg1 )
				{
					case _KEYCODE_UP:
          
            if( worldMap[ (int)( posX + dirX * moveSpeed * 5 ) ][ (int) (posY) ] == false ) 
            {
              posX += dirX * moveSpeed;
            }

            if( worldMap[ (int)( posX ) ][ (int)( posY + dirY * moveSpeed * 5 ) ] == false ) 
            {
              posY += dirY * moveSpeed;
            }

					break;

					case _KEYCODE_DOWN:
      
            if( worldMap[ (int)( posX - dirX * moveSpeed ) ][ (int)( posY ) ] == false ) 
            {
              posX -= dirX * moveSpeed;
            }

            if( worldMap[ (int)( posX ) ][ (int)( posY - dirY * moveSpeed ) ] == false ) 
            {
              posY -= dirY * moveSpeed;
            }

						break;

					case _KEYCODE_RIGHT:

            //both camera direction and camera plane must be rotated
            oldDirX = dirX;
            dirX = dirX * cos(-rotSpeed) - dirY * sin(-rotSpeed);
            dirY = oldDirX * sin(-rotSpeed) + dirY * cos(-rotSpeed);
            oldPlaneX = planeX;
            planeX = planeX * cos(-rotSpeed) - planeY * sin(-rotSpeed);
            planeY = oldPlaneX * sin(-rotSpeed) + planeY * cos(-rotSpeed);

      			break;

					case _KEYCODE_LEFT:

            //both camera direction and camera plane must be rotated
            oldDirX = dirX;
            dirX = dirX * cos(rotSpeed) - dirY * sin(rotSpeed);
            dirY = oldDirX * sin(rotSpeed) + dirY * cos(rotSpeed);
            oldPlaneX = planeX;
            planeX = planeX * cos(rotSpeed) - planeY * sin(rotSpeed);
            planeY = oldPlaneX * sin(rotSpeed) + planeY * cos(rotSpeed);   
      			
            break;
			
					case _KEYCODE_PGUP:

						break;

					case _KEYCODE_PGDOWN:

						break;

				}
			}


		} 
		
	}while( 1 );
	
} 