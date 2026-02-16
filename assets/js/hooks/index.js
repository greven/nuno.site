import { ArticleTableOfContents } from './article-toc';
import { CardStack } from './card-stack';
import { CoverImage } from './cover-image';
import { Dialog } from './dialog';
import { Drawer } from './drawer';
import { EmailLink } from './email-link';
import { Finder } from './finder';
import { Hello } from './hello';
import { Image } from './image';
import { Layout } from './layout';
import { PostLike } from './post-like';
import { PostMeta } from './post-meta';
import { ProfileSlideshow } from './profile-slideshow';
import { PulseClock } from './pulse-clock';
import { Resume } from './resume';
import { SharePost } from './share-post';
import { SiteHeader } from './site-header';
import { Spoiler } from './spoiler';
import { Tabs } from './tabs';
import { TheEnd } from './the-end';
import { ThemeSwitcher } from './theme-switcher';
import { Tooltip } from './tooltip';
import { TravelMap } from './travel-map';

// Colocated hooks
import { hooks as colocatedHooks } from 'phoenix-colocated/site';

export default {
  ArticleTableOfContents,
  CardStack,
  CoverImage,
  Dialog,
  Drawer,
  EmailLink,
  Finder,
  Hello,
  Image,
  Layout,
  PostLike,
  PostMeta,
  ProfileSlideshow,
  PulseClock,
  Resume,
  SharePost,
  SiteHeader,
  Spoiler,
  Tabs,
  TheEnd,
  ThemeSwitcher,
  Tooltip,
  TravelMap,
  ...colocatedHooks,
};
