import '../styles/globals.css';
import MetaMaskProvider from "../context/connect_mask";

export default function App({ Component, pageProps }) {
  return (
    <MetaMaskProvider>
    <Component {...pageProps} />
    </MetaMaskProvider>
  )
}
