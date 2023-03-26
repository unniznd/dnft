import { useContext } from "react";
import { AppContext } from "../context/connect_mask";


export default function LoginMetaMask() {
  const { account, connectWallet, error } = useContext(AppContext);

  console.log(error);
  return (
    <div className="flex h-screen ">
      <div className="m-auto">
        {account ? (
          <p className="text-center text-2xl">Connected to {account}</p>
        ) : (
          <button className="bg-red-500 text-white font-bold py-2 px-4 rounded" onClick={connectWallet}>
              Connect To MetaMask
          </button>
        )}
        {error && <p className={`error shadow-border align-center`}>{`Error: ${error}`}</p>}
      </div>
      </div>
  );
}